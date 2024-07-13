defmodule MavuForm.InputHelpers do
  import Phoenix.HTML
  import Phoenix.HTML.Form
  use PhoenixHTMLHelpers

  # inspired by http://blog.plataformatec.com.br/2016/09/dynamic-forms-with-phoenix/

  def theme_module(assigns) do
    module =
      (assigns.opts[:theme] ||
         get_theme_key_for_form(assigns.form))
      |> module_for_theme_key()

    Code.ensure_loaded!(module)
    module
  end

  def module_for_theme_key(theme_key) do
    Application.get_env(:mavu_form, :themes)[theme_key]
  end

  def get_theme_key_for_form(form) do
    form.options[:theme]
    |> MavuUtils.if_nil(Application.get_env(:mavu_form, :default_theme))
  end

  Phoenix.HTML.Form

  def theme_module(form, field, opts), do: theme_module(%{form: form, field: field, opts: opts})

  def input(assigns) do
    if function_exported?(theme_module(assigns), :input, 1) do
      theme_module(assigns).input(assigns)
    else
      label_block = label_block(assigns)
      input_block = input_block(assigns)

      theme_module(assigns).wrap([label_block, input_block], :container, assigns)
    end
  end

  def input(form, field, opts \\ []), do: input(create_assigns(form, field, opts))

  def label_block(%{using: :checkbox} = assigns) do
    wrapped_label = ""
    theme_module(assigns).wrap([wrapped_label], :label_block, assigns)
  end

  def label_block(assigns) do
    wrapped_label = wrapped_label(assigns)
    theme_module(assigns).wrap([wrapped_label], :label_block, assigns)
  end

  def label_block(form, field, opts \\ []), do: label_block(create_assigns(form, field, opts))

  def input_block(assigns) do
    if function_exported?(theme_module(assigns), :input_block, 1) do
      theme_module(assigns).input_block(assigns)
    else
      wrapped_input = wrapped_input(assigns)
      error_block = error_block(assigns)
      theme_module(assigns).wrap([wrapped_input, error_block], :input_block, assigns)
    end
  end

  def input_block(form, field, opts \\ []), do: input_block(create_assigns(form, field, opts))

  def error_block(assigns) do
    if function_exported?(theme_module(assigns), :error_block, 1) do
      theme_module(assigns).error_block(assigns)
    else
      []
    end
  end

  def error_block(form, field, opts \\ []), do: error_block(create_assigns(form, field, opts))

  def mark_label_as_required(inner_content, assigns) when is_map(assigns) do
    [inner_content, " *"]
  end

  def wrapped_label(assigns) do
    raw_label = raw_label(assigns)
    theme_module(assigns).wrap([raw_label], :wrapped_label, assigns)
  end

  def input_wrap(inner_content, block_name, assigns)
      when is_atom(block_name) and is_map(assigns) do
    theme_module(assigns).wrap([inner_content], block_name, assigns)
  end

  def input_wrap(form, field, block_name, opts \\ [], do: inner_content)
      when is_atom(block_name) do
    input_wrap(inner_content, block_name, create_assigns(form, field, opts))
  end

  def wrapped_label(form, field, opts \\ []),
    do: wrapped_label(create_assigns(form, field, opts))

  def wrapped_input(%{using: :checkbox} = assigns) do
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
        MavuForm.Engine.get_tag_options_for_block(:raw_label, assigns)
        |> Keyword.put(
          :class,
          MavuForm.Engine.process_classes(label_classes, :raw_label, assigns)
        )
        |> Keyword.put(:for, Phoenix.HTML.Form.input_id(assigns.form, assigns.field))

      content_tag(
        :span,
        MavuForm.process_html(assigns.opts[:label], :raw_label, assigns),
        tag_options
      )
    else
      ""
    end
  end

  def raw_label(form, field, opts \\ []), do: raw_label(create_assigns(form, field, opts))

  def raw_input(assigns) when is_map(assigns) do
    input_classes = theme_module(assigns).get_classes_for_element(:raw_input, assigns)

    tag_options =
      MavuForm.Engine.get_tag_options_for_block(:raw_input, assigns)
      |> Keyword.put(:class, MavuForm.Engine.process_classes(input_classes, :raw_input, assigns))
      |> Keyword.put(:for, Phoenix.HTML.Form.input_id(assigns.form, assigns.field))
      |> handle_value_formatter(assigns)

    case assigns.using do
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
          assigns.using,
          [assigns.form, assigns.field, tag_options]
        )
    end
  end

  defp handle_value_formatter(keywords, assigns) when is_list(keywords) and is_map(assigns) do
    value_formatter = Keyword.get(keywords, :value_formatter)

    if(MavuUtils.present?(value_formatter)) do
      if is_function(value_formatter, 1) do
        keywords
        |> Keyword.put(
          :value,
          value_formatter.(Phoenix.HTML.Form.input_value(assigns.form, assigns.field))
        )
        |> Keyword.delete(:value_formatter)
      else
        raise "value_formatter is not a function with arity of 1"
      end
    else
      keywords
    end
  end

  def raw_input(form, field, opts \\ []), do: raw_input(create_assigns(form, field, opts))

  def default_options(form, field, opts) do
    if function_exported?(theme_module(form, field, opts), :default_options, 3) do
      theme_module(form, field, opts).default_options(form, field, opts)
    else
      []
    end
  end

  def create_assigns(form, field, opts \\ []) do
    using = opts[:using] || :text_input

    %{
      form: form,
      field: field,
      opts: Keyword.merge(default_options(form, field, opts), opts),
      using: using,
      has_error: has_error(form, field, opts)
    }
  end

  def has_error(form, field, opts \\ [])

  def has_error(form, field, _opts) when is_atom(field) do
    form.errors
    |> Keyword.get_values(field)
    |> case do
      [] -> false
      _ -> true
    end
  end

  def has_error(form, field, _opts) when is_binary(field) do
    form.errors
    |> Enum.filter(fn {key, _} -> key == field end)
    |> case do
      [] -> false
      _ -> true
    end
  end
end
