defmodule BlockScoutWeb.APIDocsController do
  use BlockScoutWeb, :controller

  alias BlockScoutWeb.Etherscan
  alias Explorer.EthRPC
  alias Explorer.RPCTest

  def index(conn, _params) do
    conn
    |> assign(:documentation, Etherscan.get_documentation())
    |> render("index.html")
  end

  def eth_rpc(conn, _params) do
    conn
    |> assign(:documentation, EthRPC.methods())
    |> render("eth_rpc.html")
  end

  def api_docs_test(conn, _params) do
    conn
    |> assign(:documentation, RPCTest.methods())
    |> render("api_docs_test.html")
  end
end
