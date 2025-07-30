defmodule LiveVue.Diff do
  @moduledoc false

  alias Jsonpatch.Types

  @doc """
  Creates a patch from the difference of a source map to a destination map or list.

  ## Options

    * `:ancestor_path` - Sets the initial ancestor path for the diff operation.
      Defaults to `""` (root). Useful when you need to diff starting from a nested path.
    * `:prepare_map` - A function that prepares maps before diffing.
      Defaults to `fn map -> map end` (no-op). Useful when you need to customize
      how maps are handled during the diff process. Example:

      ```elixir
      fn
        %Struct{field1: value1, field2: value2} -> %{field1: "\#{value1} - \#{value2}"}
        %OtherStruct{} = struct -> Map.take(struct, [:field1])
        struct -> struct
      end
      ```

  ## Examples

      iex> source = %{"name" => "Bob", "married" => false, "hobbies" => ["Elixir", "Sport", "Football"]}
      iex> destination = %{"name" => "Bob", "married" => true, "hobbies" => ["Elixir!"], "age" => 33}
      iex> Jsonpatch.diff(source, destination)
      [
        %{path: "/married", value: true, op: "replace"},
        %{path: "/hobbies/2", op: "remove"},
        %{path: "/hobbies/1", op: "remove"},
        %{path: "/hobbies/0", value: "Elixir!", op: "replace"},
        %{path: "/age", value: 33, op: "add"}
      ]

      iex> source = %{"a" => 1, "b" => 2}
      iex> destination = %{"a" => 3, "c" => 4}
      iex> Jsonpatch.diff(source, destination, ancestor_path: "/nested")
      [
        %{path: "/nested/b", op: "remove"},
        %{path: "/nested/c", value: 4, op: "add"},
        %{path: "/nested/a", value: 3, op: "replace"}
      ]
  """
  @spec diff(Types.json_container(), Types.json_container(), Types.opts_diff()) ::
          [Jsonpatch.t()]
  def diff(source, destination, opts \\ []) do
    opts =
      opts
      |> Keyword.update(:object_hash, nil, &make_safe_hash_fn/1)
      |> Keyword.validate!(
        ancestor_path: "",
        prepare_map: fn map -> map end,
        object_hash: nil
      )

    do_diff(destination, source, opts[:ancestor_path], nil, [], opts)
  end

  defguardp are_unequal_maps(val1, val2) when val1 != val2 and is_map(val2) and is_map(val1)
  defguardp are_unequal_lists(val1, val2) when val1 != val2 and is_list(val2) and is_list(val1)

  defp do_diff(dest, source, path, key, patches, opts) when are_unequal_lists(dest, source) do
    # uneqal lists, let's use a specialized function for that
    do_list_diff(dest, source, join_key(path, key), patches, opts)
  end

  defp do_diff(dest, source, path, key, patches, opts) when are_unequal_maps(dest, source) do
    # Convert structs to maps if prepare_map function is provided
    dest = maybe_prepare_map(dest, opts)
    source = maybe_prepare_map(source, opts)

    if not is_map(dest) or not is_map(source) do
      # type changed, let's process it again
      do_diff(dest, source, path, key, patches, opts)
    else
      # uneqal maps, let's use a specialized function for that
      do_map_diff(dest, source, join_key(path, key), patches, opts)
    end
  end

  defp do_diff(dest, source, path, key, patches, opts) when dest != source do
    # scalar values or change of type (map -> list etc), let's just make a replace patch
    [%{op: "replace", path: join_key(path, key), value: maybe_prepare_map(dest, opts)} | patches]
  end

  defp do_diff(_dest, _source, _path, _key, patches, _opts) do
    # no changes, return patches as is
    patches
  end

  defp do_map_diff(%{} = destination, %{} = source, ancestor_path, patches, opts) do
    # entrypoint for map diff, let's convert the map to a list of {k, v} tuples
    destination
    |> Map.to_list()
    |> do_map_diff(source, ancestor_path, patches, [], opts)
  end

  defp do_map_diff([], source, ancestor_path, patches, checked_keys, _opts) do
    # The complete desination was check. Every key that is not in the list of
    # checked keys, must be removed.
    Enum.reduce(source, patches, fn {k, _}, patches ->
      if k in checked_keys do
        patches
      else
        [%{op: "remove", path: join_key(ancestor_path, k)} | patches]
      end
    end)
  end

  defp do_map_diff([{key, val} | rest], source, ancestor_path, patches, checked_keys, opts) do
    # normal iteration through list of map {k, v} tuples. We track seen keys to later remove not seen keys.
    patches =
      case Map.fetch(source, key) do
        {:ok, source_val} ->
          do_diff(val, source_val, ancestor_path, key, patches, opts)

        :error ->
          [%{op: "add", path: join_key(ancestor_path, key), value: maybe_prepare_map(val, opts)} | patches]
      end

    # Diff next value of same level
    do_map_diff(rest, source, ancestor_path, patches, [key | checked_keys], opts)
  end

  defp do_list_diff(destination, source, ancestor_path, patches, opts) do
    if opts[:object_hash] do
      do_hash_list_diff(destination, source, ancestor_path, patches, opts)
    else
      do_pairwise_list_diff(destination, source, ancestor_path, patches, 0, opts)
    end
  catch
    # happens if we've got a nil hash or we tried to hash a non-map
    :hash_not_implemented -> do_pairwise_list_diff(destination, source, ancestor_path, patches, 0, opts)
  end

  defp do_pairwise_list_diff(destination, source, ancestor_path, patches, idx, opts)

  defp do_pairwise_list_diff([], [], _path, patches, _idx, _opts), do: patches

  defp do_pairwise_list_diff([], [_item | source_rest], ancestor_path, patches, idx, opts) do
    # if we find any leftover items in source, we have to remove them
    patches = [%{op: "remove", path: join_key(ancestor_path, idx)} | patches]
    do_pairwise_list_diff([], source_rest, ancestor_path, patches, idx + 1, opts)
  end

  defp do_pairwise_list_diff(items, [], ancestor_path, patches, idx, opts) do
    # we have to do it without recursion, because we have to keep the order of the items
    items
    |> Enum.map_reduce(idx, fn val, idx ->
      {%{op: "add", path: join_key(ancestor_path, idx), value: maybe_prepare_map(val, opts)}, idx + 1}
    end)
    |> elem(0)
    |> Kernel.++(patches)
  end

  defp do_pairwise_list_diff([val | rest], [source_val | source_rest], ancestor_path, patches, idx, opts) do
    # case when there's an item in both desitation and source. Let's just compare them
    patches = do_diff(val, source_val, ancestor_path, idx, patches, opts)
    do_pairwise_list_diff(rest, source_rest, ancestor_path, patches, idx + 1, opts)
  end

  defp do_hash_list_diff(destination, source, ancestor_path, patches, opts) do
    hash_fn = Keyword.fetch!(opts, :object_hash)

    {additions, modifications, removals} =
      greedy_find_additions_modifications_removals(
        List.to_tuple(destination),
        List.to_tuple(source),
        index_by(destination, hash_fn),
        index_by(source, hash_fn),
        hash_fn,
        ancestor_path,
        opts
      )

    List.flatten([removals, additions, modifications, patches])
  end

  defp greedy_find_additions_modifications_removals(
         dest,
         source,
         dest_map,
         source_map,
         hash_fn,
         path,
         opts,
         dest_idx \\ 0,
         source_idx \\ 0,
         additions \\ [],
         modifications \\ [],
         removals \\ []
       ) do
    cond do
      tuple_size(dest) == dest_idx ->
        # we're at the end of the destination tuple, let's remove all remaining source items
        removals = add_removals(source_idx, tuple_size(source) - 1, path, removals)
        {Enum.reverse(additions), modifications, removals}

      tuple_size(source) == source_idx ->
        # we're at the end of the source tuple, let's add all remaining destination items
        additions = add_additions(dest_idx, tuple_size(dest) - 1, path, dest, additions, opts)
        {Enum.reverse(additions), modifications, removals}

      true ->
        # we're in the middle of the tuples, let's find the next matching items
        dest_item = elem(dest, dest_idx)
        source_item = elem(source, source_idx)

        source_hash = hash_fn.(source_item)
        dest_hash = hash_fn.(dest_item)

        if source_hash == dest_hash do
          # same items, let's diff recursively and bump both indexes
          modifications = do_diff(dest_item, source_item, path, dest_idx, modifications, opts)

          greedy_find_additions_modifications_removals(
            dest,
            source,
            dest_map,
            source_map,
            hash_fn,
            path,
            opts,
            dest_idx + 1,
            source_idx + 1,
            additions,
            modifications,
            removals
          )
        else
          # different items, let's find index of destination item in source and vice versa
          {next_dest_idx, next_source_idx} =
            determine_next_idx(
              dest_idx,
              source_idx,
              Map.get(dest_map, source_hash),
              Map.get(source_map, dest_hash)
            )

          removals = add_removals(source_idx, next_source_idx - 1, path, removals)
          additions = add_additions(dest_idx, next_dest_idx - 1, path, dest, additions, opts)

          greedy_find_additions_modifications_removals(
            dest,
            source,
            dest_map,
            source_map,
            hash_fn,
            path,
            opts,
            next_dest_idx,
            next_source_idx,
            additions,
            modifications,
            removals
          )
        end
    end
  end

  defp determine_next_idx(d_idx, s_idx, next_d_idx, next_s_idx) do
    dest_found = next_d_idx != nil and next_d_idx > d_idx
    source_found = next_s_idx != nil and next_s_idx > s_idx
    source_closer = dest_found and source_found and next_s_idx - s_idx < next_d_idx - d_idx

    cond do
      # in case when we can jump to either of them, we want to jump to the closer one
      source_closer -> {d_idx, next_s_idx}
      # only source is found ahead, we have to do source jump
      next_d_idx == nil and source_found -> {d_idx, next_s_idx}
      # only dest is found ahead, we have to do dest jump
      next_s_idx == nil and dest_found -> {next_d_idx, s_idx}
      # neither is found ahead, we have to advance both indexes
      true -> {d_idx + 1, s_idx + 1}
    end
  end

  @compile {:inline, index_by: 2}
  defp index_by(list, hash_fn) do
    list
    |> Enum.reduce({%{}, 0}, fn item, {map, idx} ->
      # if we have a hash collision, we throw an error and handle as if the hash is not implemented
      {Map.update(map, hash_fn.(item), idx, fn _ -> throw(:hash_not_implemented) end), idx + 1}
    end)
    |> elem(0)
  end

  @compile {:inline, add_removals: 4}
  defp add_removals(from_idx, to_idx, path, removals) do
    Enum.reduce(from_idx..to_idx//1, removals, fn idx, removals ->
      [%{op: "remove", path: join_key(path, idx)} | removals]
    end)
  end

  @compile {:inline, add_additions: 6}
  defp add_additions(from_idx, to_idx, path, dest_tuple, additions, opts) do
    Enum.reduce(from_idx..to_idx//1, additions, fn idx, additions ->
      value = dest_tuple |> elem(idx) |> maybe_prepare_map(opts)
      [%{op: "add", path: join_key(path, idx), value: value} | additions]
    end)
  end

  @compile {:inline, escape: 1}
  defp escape(fragment) when is_binary(fragment) do
    fragment =
      if :binary.match(fragment, "~") == :nomatch,
        do: fragment,
        else: String.replace(fragment, "~", "~0")

    if :binary.match(fragment, "/") == :nomatch,
      do: fragment,
      else: String.replace(fragment, "/", "~1")
  end

  defp escape(fragment), do: fragment

  @compile {:inline, join_key: 2}
  defp join_key(path, nil), do: path
  defp join_key(path, key), do: "#{path}/#{escape(key)}"

  defp make_safe_hash_fn(hash_fn) do
    # we want to compare only maps, and returning nil should mean
    # we should compare lists pairwise instead
    fn
      %{} = item ->
        case hash_fn.(item) do
          nil -> throw(:hash_not_implemented)
          hash -> hash
        end

      _item ->
        throw(:hash_not_implemented)
    end
  end

  defp maybe_prepare_map(value, opts) when is_map(value) do
    prepare_fn = Keyword.fetch!(opts, :prepare_map)
    prepare_fn.(value)
  end

  defp maybe_prepare_map(value, _opts), do: value
end
