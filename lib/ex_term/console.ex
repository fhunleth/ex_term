defmodule ExTerm.Console do
  @moduledoc false

  # ExTerm.Console is a datastructure/component which describes the "console" region of
  # the ExTerm interface.  This is a (currently 40r x 80c) matrix of characters
  # which contain their own individual styling elements.  The console also
  # retains a cursor position, which can move around.

  # In the future, this will likely support arbitrary row/column counts.

  use Phoenix.Component

  alias ExTerm.Console.Row
  alias ExTerm.Console.Data
  alias ExTerm.Style

  @type t :: :ets.table()
  @type rows :: %{optional(pos_integer) => Row.t()}

  def render(assigns) do
    ~H"""
    <div id="exterm-console">
      <%= for row <- @rows do %>
      <Row.render row={row} cursor={@cursor} prompt={@prompt}/>
      <% end %>
    </div>
    """
  end

  #############################################################################
  ## API

  @type dimension_request :: :rows | :column
  @spec get_dimension(t, dimension_request) :: non_neg_integer

  @spec put_chars(t, String.t()) :: t
  @spec push_key(t, String.t()) :: boolean

  #############################################################################
  ## API IMPLEMENTATIONS

  def get_dimension(data, request \\ [:columns, :rows]) do
    case Data.metadata(data, request) do
      [column, row] -> {row, column}
      result -> result
    end
  end

  def put_chars(console, chars) do
    do_put_char(console, chars)
  end

  def push_key(console, key) do
    do_put_char(console, key)
  end

  #############################################################################
  ## COMMON FUNCTIONS

  defp do_put_char(result, ""), do: result

  @control 27

  defp do_put_char(console, chars = <<@control, _::binary>>) do
    style = Data.metadata(console, :style)
    {style, rest} = Style.from_ansi(style, chars)
    Data.put_metadata(console, style: style)

    do_put_char(console, rest)
  end

  defp do_put_char(console, chars) do
    {head, rest} = String.next_grapheme(chars)

    console
    |> put_char_in_place(head)
    |> do_put_char(rest)
  end

  defp put_char_in_place(console, "\n"), do: cursor_crlf(console)

  defp put_char_in_place(console, char) do
    Data.put_char(console, char)
  end

  defdelegate cursor_advance(console, columns), to: Data
  defdelegate cursor_crlf(console), to: Data
  defdelegate paint_chars(console, location, content, cursor_offset), to: Data
end
