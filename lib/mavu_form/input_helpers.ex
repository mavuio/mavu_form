defmodule MavuForm.InputHelpers do
  use Phoenix.HTML

  # import Mavuform

  # inspired by http://blog.plataformatec.com.br/2016/09/dynamic-forms-with-phoenix/

  def theme_module(_assigns) do
    MyAppBe.TwHorizontalInputTheme
  end

  def input(assigns) do
    label_block = label_block(assigns)
    input_block = input_block(assigns)

    theme_module(assigns).wrap([label_block, input_block], :container, assigns)
  end

  def input(form, field, opts \\ []), do: input(create_assigns(form, field, opts))

  def label_block(%{type: :checkbox} = assigns) do
    wrapped_label = ""
    theme_module(assigns).wrap([wrapped_label], :label_block, assigns)
  end

  def label_block(assigns) do
    wrapped_label = wrapped_label(assigns)
    theme_module(assigns).wrap([wrapped_label], :label_block, assigns)
  end

  def label_block(form, field, opts \\ []), do: label_block(create_assigns(form, field, opts))

  def input_block(assigns) do
    wrapped_input = wrapped_input(assigns)
    error_block = error_block(assigns)
    theme_module(assigns).wrap([wrapped_input, error_block], :input_block, assigns)
  end

  def error_block(assigns) do
    theme_module(assigns).error_block(assigns)
  end

  def error_block(form, field, opts \\ []), do: error_block(create_assigns(form, field, opts))

  def input_block(form, field, opts \\ []), do: input_block(create_assigns(form, field, opts))

  def wrapped_label(assigns) do
    raw_label = raw_label(assigns)
    theme_module(assigns).wrap([raw_label], :wrapped_label, assigns)
  end

  def wrapped_label(form, field, opts \\ []),
    do: wrapped_label(create_assigns(form, field, opts))

  def wrapped_input(%{type: :checkbox} = assigns) do
    raw_input = raw_input(assigns)
    wrapped_label = wrapped_label(assigns)
    theme_module(assigns).wrap([raw_input, wrapped_label], :wrapped_input, assigns)
  end

  def wrapped_input(assigns) do
    raw_input = raw_input(assigns)
    theme_module(assigns).wrap([raw_input], :wrapped_input, assigns)
  end

  def wrapped_input(form, field, opts \\ []),
    do: wrapped_input(create_assigns(form, field, opts))

  def raw_label(assigns) do
    if assigns.opts[:label] do
      label_classes = theme_module(assigns).get_classes_for_element(:raw_label, assigns)

      tag_options =
        MavuForm.MfUtils.get_tag_options_for_block(:raw_label, assigns)
        |> Keyword.put(
          :class,
          MavuForm.MfUtils.process_classes(label_classes, :raw_label, assigns)
        )
        |> Keyword.put(:for, Phoenix.HTML.Form.input_id(assigns.form, assigns.field))

      content_tag(:label, assigns.opts[:label], tag_options)
    else
      ""
    end
  end

  def raw_label(form, field, opts \\ []), do: raw_label(create_assigns(form, field, opts))

  def raw_input(assigns) do
    input_classes = theme_module(assigns).get_classes_for_element(:raw_input, assigns)

    tag_options =
      MavuForm.MfUtils.get_tag_options_for_block(:raw_input, assigns)
      |> Keyword.put(:class, MavuForm.MfUtils.process_classes(input_classes, :raw_input, assigns))
      |> Keyword.put(:for, Phoenix.HTML.Form.input_id(assigns.form, assigns.field))

    case assigns.type do
      :select ->
        Phoenix.HTML.Form.select(
          assigns.form,
          assigns.field,
          assigns.opts[:items],
          tag_options
        )

      _ ->
        apply(
          Phoenix.HTML.Form,
          assigns.type,
          [assigns.form, assigns.field, tag_options]
        )
    end
  end

  def raw_input(form, field, opts \\ []), do: raw_input(create_assigns(form, field, opts))

  def create_assigns(form, field, opts \\ []) do
    type = opts[:using] || :text_input

    %{
      form: form,
      field: field,
      opts: opts,
      type: type,
      has_error: has_error(form, field, opts)
    }
  end

  def has_error(form, field, _opts \\ []) do
    form.errors
    |> Keyword.get_values(field)
    |> case do
      [] -> false
      _ -> true
    end
  end
end
