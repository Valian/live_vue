{application,nodejs,
             [{modules,['Elixir.NodeJS','Elixir.NodeJS.Error',
                        'Elixir.NodeJS.Supervisor','Elixir.NodeJS.Worker']},
              {optional_applications,[]},
              {applications,[kernel,stdlib,elixir,logger,jason,poolboy,
                             ssl_verify_fun]},
              {description,"Provides an Elixir API for calling Node.js functions.\n"},
              {registered,[]},
              {vsn,"3.1.2"}]}.
