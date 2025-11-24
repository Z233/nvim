--- Treesitter utility module for detecting function names in JavaScript/TypeScript code
--- Used by timber.nvim to add function name prefixes to log statements

local M = {}

--- Extract function name from a Treesitter node
--- @param node table|nil Treesitter node
--- @return string|nil Function name or nil if not found
local function get_function_name(node)
  if not node then return nil end

  local node_type = node:type()

  -- Named function declaration: function foo() {}
  if node_type == "function_declaration" then
    for child in node:iter_children() do
      if child:type() == "identifier" then
        return vim.treesitter.get_node_text(child, 0)
      end
    end
  end

  -- Method definition: class methods or object methods
  if node_type == "method_definition" or node_type == "pair" then
    for child in node:iter_children() do
      if child:type() == "property_identifier" or child:type() == "identifier" then
        return vim.treesitter.get_node_text(child, 0)
      end
    end
  end

  -- Arrow function or function expression assigned to variable
  -- Look for: const foo = () => {} or const foo = function() {}
  if node_type == "arrow_function" or node_type == "function_expression" or node_type == "function" then
    local parent = node:parent()
    if parent then
      local parent_type = parent:type()

      -- Variable declarator: const foo = ...
      if parent_type == "variable_declarator" then
        for child in parent:iter_children() do
          if child:type() == "identifier" then
            return vim.treesitter.get_node_text(child, 0)
          end
        end
      end

      -- Assignment: foo = ...
      if parent_type == "assignment_expression" then
        for child in parent:iter_children() do
          if child:type() == "identifier" or child:type() == "member_expression" then
            return vim.treesitter.get_node_text(child, 0)
          end
        end
      end

      -- Object property: { foo: () => {} }
      if parent_type == "pair" then
        for child in parent:iter_children() do
          if child:type() == "property_identifier" or child:type() == "identifier" then
            return vim.treesitter.get_node_text(child, 0)
          end
        end
      end
    end
  end

  return nil
end

--- Find the containing function name by traversing up the syntax tree
--- @param ctx table Context object from timber.nvim containing log_target
--- @return string Function name or "[global]" if not in a function
function M.find_function_name(ctx)
  if not ctx or not ctx.log_target then
    return "[global]"
  end

  local node = ctx.log_target

  -- Traverse up the syntax tree
  while node do
    local node_type = node:type()

    -- Check if this is a function-like node
    if node_type == "function_declaration" or
       node_type == "method_definition" or
       node_type == "arrow_function" or
       node_type == "function_expression" or
       node_type == "function" or
       node_type == "pair" then

      local func_name = get_function_name(node)
      if func_name then
        return func_name
      end
    end

    -- Move to parent
    node = node:parent()
  end

  return "[global]"
end

return M
