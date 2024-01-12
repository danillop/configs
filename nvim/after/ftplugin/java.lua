local home = os.getenv('HOME')
local opts = {
  cmd = {},
  settings = {
    java = {
      signatureHelp = { enabled = true },
      completion = {
        favoriteStaticMembers = {},
        filteredTypes = {
           "com.sun.*",
           "io.micrometer.shaded.*",
           "java.awt.*",
            "jdk.*",
            "sun.*",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
        },
        useBlocks = true,
      },
      configuration = {
        runtimes = {
          {
            name = "JavaSE-11",
            path = home .. "/.sdkman/candidates/java/11.0.9.hs-adpt",
          },
          {
              name = "JavaSE-1.8",
              path = home .. "/.sdkman/candidates/java/8.0.342-amzn",
          }
        },
      },
    },
  },
}

local function setup()
  local jdtls = jaylib.loadpkg("jdtls")
  if jdtls == nil then
    return {}
  end

  -- local jdtls_path = vim.fn.stdpath("data") .. "/mason/packages/jdtls"
  local jdtls_bin = vim.fn.stdpath("data") .. "/mason/bin/jdtls"

  local root_markers = { ".gradle", "gradlew", ".git" }
  local root_dir = jdtls.setup.find_root(root_markers)
  local home = os.getenv("HOME")
  local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
  local workspace_dir = home .. "/.cache/jdtls/workspace/" .. project_name

  opts.cmd = {
    jdtls_bin,
    "-data",
    workspace_dir,
  }
  local common_opts = require("lsp").get_common_options()

  local on_attach = function(client, bufnr)
      -- Regular Neovim LSP client keymappings
      local bufopts = { noremap=true, silent=true, buffer=bufnr }
      nnoremap('gd', vim.lsp.buf.definition, bufopts, "Go to definition")
      nnoremap('gi', vim.lsp.buf.implementation, bufopts, "Go to implementation")
      nnoremap('gD', vim.lsp.buf.declaration, bufopts, "Go to declaration")
      nnoremap('K', vim.lsp.buf.hover, bufopts, "Hover text")
      nnoremap('<C-k>', vim.lsp.buf.signature_help, bufopts, "Show signature")
      nnoremap('<leader>wa', vim.lsp.buf.add_workspace_folder, bufopts, "Add workspace folder")
      nnoremap('<leader>ww', vim.lsp.buf.remove_workspace_folder, bufopts, "Remove workspace folder")
      nnoremap('<leader>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, bufopts, "List workspace folders")
      nnoremap('<space>D', vim.lsp.buf.type_definition, bufopts, "Go to type definition")
      nnoremap('<space>rn', vim.lsp.buf.rename, bufopts, "Rename")
      nnoremap('<space>ca', vim.lsp.buf.code_action, bufopts, "Code actions")
      vim.keymap.set('v', "<space>ca", "<ESC><CMD>lua vim.lsp.buf.range_code_action()<CR>",
      { noremap=true, silent=true, buffer=bufnr, desc = "Code actions" })
      nnoremap('<space>f', function() vim.lsp.buf.format { async = true } end, bufopts, "Format file")

      -- Java extensions provided by jdtls
      nnoremap("<C-o>", jdtls.organize_imports, bufopts, "Organize imports")
      nnoremap("<space>ev", jdtls.extract_variable, bufopts, "Extract variable")
      nnoremap("<space>ec", jdtls.extract_constant, bufopts, "Extract constant")
      vim.keymap.set('v', "<space>em", [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
      { noremap=true, silent=true, buffer=bufnr, desc = "Extract method" })

      jdtls.setup.add_commands()
      -- vim.lsp.codelens.refresh()
      -- if JAVA_DAP_ACTIVE then
      jdtls.setup_dap({ hotcodereplace = "auto" })
    jdtls.dap.setup_dap_main_class_configs()
    -- end
    common_opts.on_attach(client, bufnr)
  end

  opts.on_attach = on_attach
  opts.capabilities = common_opts.capabilities
  return opts
end

return { setup = setup }
