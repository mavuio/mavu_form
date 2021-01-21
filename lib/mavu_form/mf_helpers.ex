defmodule MavuForm.MfHelpers do
  @moduledoc """
    MavuForm helpers by Manfred Wuits
  """

  defmacro pipe_when(left, condition, fun) do
    quote do
      left = unquote(left)

      if unquote(condition),
        do: left |> unquote(fun),
        else: left
    end
  end

  def if_empty(val, default_val) do
    if present?(val) do
      val
    else
      default_val
    end
  end

  def if_nil(val, default_val) do
    if is_nil(val) do
      default_val
    else
      val
    end
  end

  def present?(term) do
    !Blankable.blank?(term)
  end

  def empty?(term) do
    Blankable.blank?(term)
  end

  def false?(false), do: true
  def false?("false"), do: true
  def false?(-1), do: true
  def false?(0), do: true
  def false?("0"), do: true
  def false?("-1"), do: true

  def false?(term) do
    empty?(term)
  end

  def true?(true), do: true
  def true?("true"), do: true
  def true?(1), do: true
  def true?("1"), do: true

  def true?(term) do
    !false?(term)
  end
end
