defmodule MiniIrcd.Server do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: :miniircd])
  end

  def init([]) do
    server = Socket.TCP.listen!(6667, packet: :line)
    {:ok, %{server: server}, 0}
  end

  def handle_info(:timeout, %{server: server} = state) do
    Logger.debug "accepting connection"
    client = server |> Socket.TCP.accept!(mode: :once)
    Logger.debug "client joined"
    #TODO: supervise this pid
    {:ok, client_pid} = MiniIrcd.Client.start(client)
    Socket.TCP.process!(client, client_pid)
    Logger.debug "connection is handed over to #{inspect client_pid}"
    {:noreply, state, 0}
  end
end
