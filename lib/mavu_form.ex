defmodule MavuForm do
  defdelegate get_tag_options_for_block(blockname, assigns), to: MavuForm.Engine
  defdelegate process_classes(classnames, block_name, assigns), to: MavuForm.Engine
  defdelegate process_html(html, block_name, assigns), to: MavuForm.Engine
end
