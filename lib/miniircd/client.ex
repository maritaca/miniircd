defmodule MiniIrcd.Client do
  use GenServer
  require Logger

  def start(client) do
    Supervisor.start_child MiniIrcd.Client.Supervisor, [client]
  end

  def start_link(client) do
    GenServer.start_link(__MODULE__, [client], [])
  end

  def init([client]) do
    {:ok, %{client: client}}
  end

  def handle_info({:tcp, client, line}, %{client: client} = state) do
    Socket.TCP.options(client, mode: :once)
    IO.inspect line
    case parse_request(line) do
      :exit ->
        IO.inspect(:exit)
        {:stop, :normal, state}
      res when is_list(res) ->
        res = res
              |> Enum.map(&(&1 <> "\r\n"))
              |> Enum.join
        client
        |> Socket.Stream.send(res)
        IO.inspect res
        {:noreply, state}
      oth ->
        IO.inspect(oth)
        {:noreply, state}
    end
  end

  def handle_info({:tcp_closed, client}, %{client: client} = state) do
    {:stop, :normal, state}
  end

  def parse_request(nil), do: nil
  def parse_request("CAP LS\r\n"), do: nil
  def parse_request(["NICK" | tail]) do
    tail
  end
  def parse_request(["USER" | _tail]) do
    [
      ":miniircd.local 001 milad :Hi, welcome to IRC",
      ":miniircd.local 001 milad :.. enjoy your stay :P",
    ]
  end

  def parse_request(["MODE" | _tail]) do
    [":miniircd.local 002 milad :Unknown MODE flag"]
  end

  def parse_request(["PING" | _tail]) do
    [":miniircd.local PONG"]
  end

  def parse_request(["QUIT" | _tail]) do
    :exit
  end
  def parse_request([_head| _tail] = cmd) do
    IO.inspect cmd
    throw :not_imp
  end

  def parse_request(request) do
    request
    |> String.trim
    |> String.split(" ", parts: 2)
    |> parse_request
  end
end
