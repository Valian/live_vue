otp_release = :erlang.system_info(:otp_release) |> List.to_integer()

exclude =
  if otp_release < 27 do
    [:quickbeam_ssr]
  else
    []
  end

ExUnit.start(exclude: exclude)
