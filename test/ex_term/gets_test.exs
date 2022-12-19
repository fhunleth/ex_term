defmodule ExTermTest.GetsTest do
  use ExUnit.Case, async: true
  use ExTermWeb.ConnCase

  alias ExTermTest.FlokiTools
  alias IEx.Server.Relay

  import Phoenix.LiveViewTest

  setup do
    Relay.init()
  end

  defp push_key(view, key) do
    view
    |> element("#exterm-terminal")
    |> render_keydown(%{"key" => key})
    |> Floki.parse_document!()
  end

  describe "when io is gotten" do
    test "you get a prompt and it moves the cursor, and gets the result", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")

      refute html
      |> Floki.parse_document!
      |> FlokiTools.cursor_active?

      relay_pid = Relay.pid()

      future =
        Task.async(fn ->
          IO.gets(relay_pid, "prompt")
        end)

      # sleep for 100ms
      # TODO: figure out a way to subscribe to these changes.
      Process.sleep(100)

      doc =
        view
        |> render
        |> Floki.parse_document!()

      assert "prompt" = FlokiTools.line_to_text(doc, 1)
      assert {1, 7} = FlokiTools.cursor_location(doc)
      assert FlokiTools.cursor_active?(doc)

      assert "a" == view
             |> push_key("a")
             |> FlokiTools.char_at(1, 7)

      doc = push_key(view, "Enter")
      assert {2, 1} = FlokiTools.cursor_location(doc)

      assert "a" == Task.await(future)
    end
  end
end