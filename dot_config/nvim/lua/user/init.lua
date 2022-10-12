local config = {
	header = {
		" ",
		" ",
		" ",
		" ",
		"    ███    ██ ██    ██ ██ ███    ███",
		"    ████   ██ ██    ██ ██ ████  ████",
		"    ██ ██  ██ ██    ██ ██ ██ ████ ██",
		"    ██  ██ ██  ██  ██  ██ ██  ██  ██",
		"    ██   ████   ████   ██ ██      ██",
		" ",
		" ",
		" ",
	},
	-- Configure AstroNvim updates
	updater = {
		remote = "origin", -- remote to use
		channel = "nightly", -- "stable" or "nightly"
		version = "latest", -- "latest", tag name, or regex search like "v1.*" to only do updates before v2 (STABLE ONLY)
		branch = "nightly", -- branch name (NIGHTLY ONLY)
		commit = nil, -- commit hash (NIGHTLY ONLY)
		pin_plugins = true, -- true, false, or a string for a specific AstroNvim snapshot to use (true will only track the current version if channel is "stable")
		skip_prompts = false, -- skip prompts about breaking changes
		show_changelog = true, -- show the changelog after performing an update
		-- remotes = { -- easily add new remotes to track
		--   ["remote_name"] = "https://remote_url.come/repo.git", -- full remote url
		--   ["remote2"] = "github_user/repo", -- GitHub user/repo shortcut,
		--   ["remote3"] = "github_user", -- GitHub user assume AstroNvim fork
		-- },
	},
	-- Set colorscheme
	colorscheme = "catppuccin",
	-- set vim options here (vim.<first_key>.<second_key> =  value)
	options = {
		opt = {
			relativenumber = true, -- sets vim.opt.relativenumber
			cmdheight = 0,
			-- foldnestmax = 3,
			-- foldcolumn = '3',
		},
		g = {
			mapleader = " ", -- sets vim.g.mapleader
		},
	},
	-- Default theme configuration
	default_theme = {
		diagnostics_style = { italic = true },
		-- Modify the color table
		colors = {
			fg = "#abb2bf",
		},
		-- Modify the highlight groups
		highlights = function(highlights)
			local C = require("default_theme.colors")

			highlights.Normal = { fg = C.fg, bg = C.bg }
			return highlights
		end,
		plugins = {
			-- enable or disable extra plugin highlighting
			aerial = true,
			beacon = false,
			bufferline = true,
			dashboard = true,
			highlighturl = true,
			hop = false,
			indent_blankline = true,
			lightspeed = false,
			["neo-tree"] = true,
			notify = true,
			["nvim-tree"] = false,
			["nvim-web-devicons"] = true,
			rainbow = true,
			symbols_outline = true,
			telescope = true,
			vimwiki = false,
			["which-key"] = true,
		},
	},
	-- Disable AstroNvim ui features
	ui = {
		nui_input = true,
		telescope_select = true,
	},
	-- Configure plugins
	plugins = {
		-- Add plugins, the packer syntax without the "use"
		init = {
			-- You can disable default plugins as follows:
			-- ["goolord/alpha-nvim"] = { disable = true },

			-- You can also add new plugins here as well:
			-- { "andweeb/presence.nvim" },
			-- {
			--   "ray-x/lsp_signature.nvim",
			--   event = "BufRead",
			--   config = function()
			--     require("lsp_signature").setup()
			--   end,
			-- },
			{
				"nvim-treesitter/nvim-treesitter-context",
			},
			{ "j-hui/fidget.nvim" },
			{ "VonHeikemen/searchbox.nvim" },
			{
				"nvim-lua/plenary.nvim",
			},
			{
				"folke/todo-comments.nvim",
				requires = "nvim-lua/plenary.nvim",
				config = function()
					require("todo-comments").setup({})
				end,
			},
			{
				"catppuccin/nvim",
				as = "catppuccin",
				config = function()
					require("catppuccin").setup({})
				end,
			},
			{ "echasnovski/mini.nvim", branch = "stable" },
			-- {
			-- 	"lewis6991/hover.nvim",
			-- 	config = function()
			-- 		require("hover").setup({
			-- 			init = function()
			-- 				-- Require providers
			-- 				require("hover.providers.lsp")
			-- 				-- require("hover.providers.gh")
			-- 				-- require("hover.providers.man")
			-- 				-- require("hover.providers.dictionary")
			-- 			end,
			-- 			preview_opts = {
			-- 				border = nil,
			-- 			},
			-- 			title = true,
			-- 		})
			--
			-- 		 -- Setup keymaps
			-- 		 vim.keymap.set("n", "gh", require("hover").hover, { desc = "hover.nvim" })
			-- 		 vim.keymap.set("n", "gH", require("hover").hover_select, { desc = "hover.nvim (select)" })
			-- 	end,
			-- },
			{
				"folke/trouble.nvim",
				requires = "kyazdani42/nvim-web-devicons",
				config = function()
					require("trouble").setup({})
				end,
			},
			{
				"folke/lsp-colors.nvim",
			},
			{
				"zbirenbaum/copilot.lua",
				event = { "VimEnter" },
				config = function()
					vim.defer_fn(function()
						require("copilot").setup({
							cmp = {
								enabled = true,
								method = "getCompletionsCycling",
							},
							panel = { -- no config options yet
								enabled = true,
							},
							ft_disable = {},
							plugin_manager_path = vim.fn.stdpath("data") .. "/site/pack/packer",
							server_opts_overrides = {},
						})
					end, 100)
				end,
			},
			{
				"zbirenbaum/copilot-cmp",
				module = "copilot_cmp",
				after = "nvim-cmp",
				config = function()
					astronvim.add_user_cmp_source("copilot")
				end,
			},
			{
				"ggandor/leap.nvim",
				requires = "tpope/vim-repeat",
				config = function()
					local l = require("leap")
					l.set_default_keymaps()
				end,
			},
			{
				"kylechui/nvim-surround",
				config = function()
					require("nvim-surround").setup({})
				end,
			},
			{
				"kosayoda/nvim-lightbulb",
				requires = "antoinemadec/FixCursorHold.nvim",
				config = function()
					require("nvim-lightbulb").setup({ autocmd = { enabled = true } })
				end,
			},
			{
				"windwp/nvim-spectre",
				requires = "windwp/nvim-spectre",
			},
			{
				"bkad/CamelCaseMotion",
				config = function()
					vim.api.nvim_set_var("camelcasemotion_key", "<leader>")
				end,
			},
			{
				"jose-elias-alvarez/typescript.nvim",
				after = "mason-lspconfig.nvim",
				config = function()
					require("typescript").setup({
						server = astronvim.lsp.server_settings("tsserver"),
					})
				end,
			},
			{
				"hashivim/vim-terraform",
			},
			{
				"tpope/vim-eunuch",
			},
			{
				"kevinhwang91/nvim-ufo",
				requires = "kevinhwang91/promise-async",
				config = function()
					-- vim.o.foldcolumn = "0"
					-- vim.o.foldnestmax = 3
					vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
					vim.o.foldlevelstart = 99
					vim.o.foldenable = true

					-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
					vim.keymap.set("n", "zR", require("ufo").openAllFolds)
					vim.keymap.set("n", "zM", require("ufo").closeAllFolds)

					local ftMap = {
						vim = "indent",
						python = { "indent" },
						git = "",
					}

					local function customizeSelector(bufnr)
						local function handleFallbackException(err, providerName)
							if type(err) == "string" and err:match("UfoFallbackException") then
								return require("ufo").getFolds(providerName, bufnr)
							else
								return require("promise").reject(err)
							end
						end

						return require("ufo")
								.getFolds("lsp", bufnr)
								:catch(function(err)
									return handleFallbackException(err, "treesitter")
								end)
								:catch(function(err)
									return handleFallbackException(err, "indent")
								end)
					end

					require("ufo").setup({
						provider_selector = function(bufnr, filetype, buftype)
							return ftMap[filetype] or customizeSelector
						end,
					})
				end,
			},
			{
				"mg979/vim-visual-multi",
			},
			{
				"axelvc/template-string.nvim",
				config = function()
					require("template-string").setup({
						filetypes = {
							"typescript",
							"javascript",
							"javascriptreact",
							"typescriptreact",
							"svelte",
							"vue",
						},
						jsx_brackets = true,
					})
				end,
			},
		},
		["mason-lspconfig"] = {
			ensure_installed = { "tsserver", "sumneko_lua" },
		},
		-- All other entries override the setup() call for default plugins
		["null-ls"] = function(config)
			local null_ls = require("null-ls")
			-- Check supported formatters and linters
			-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
			-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
			config.sources = {
				null_ls.builtins.formatting.eslint_d,
				null_ls.builtins.code_actions.eslint_d,
				null_ls.builtins.diagnostics.eslint_d,
				null_ls.builtins.diagnostics.luacheck,
				null_ls.builtins.diagnostics.mypy,
				null_ls.builtins.code_actions.shellcheck,
				null_ls.builtins.completion.tags,
				null_ls.builtins.formatting.markdownlint,
				null_ls.builtins.formatting.prettier,
				null_ls.builtins.formatting.terrafmt,
				null_ls.builtins.formatting.terraform_fmt,
				null_ls.builtins.formatting.gofumpt,
				null_ls.builtins.formatting.shfmt,
				null_ls.builtins.diagnostics.tsc,
				-- null_ls.builtins.formatting.black.with({ extra_args = { "--fast" } }),
				null_ls.builtins.formatting.black,
				null_ls.builtins.formatting.isort,
				null_ls.builtins.formatting.stylua,
				-- null_ls.builtins.diagnostics.pylint,
			}
			-- set up null-ls's on_attach function
			-- config.on_attach = function(client, bufnr)
			-- 	-- NOTE: You can remove this on attach function to disable format on save
			-- 	if client.resolved_capabilities.document_formatting then
			-- 		vim.api.nvim_create_autocmd("BufWritePre", {
			-- 			desc = "Auto format before save",
			-- 			pattern = "<buffer>",
			-- 			callback = function()
			-- 				return vim.lsp.buf.formatting_sync({
			-- 					bufnr = bufnr,
			-- 					filter = function(client)
			-- 						return client.name == "null-ls"
			-- 					end,
			-- 				})
			-- 			end,
			-- 		})
			-- 	end
			-- end
			return config -- return final config table
		end,
		treesitter = {
			ensure_installed = { "lua" },
		},
		packer = {
			compile_path = vim.fn.stdpath("config") .. "/lua/packer_compiled.lua",
		},
		{
			"numToStr/Comment.nvim",
			config = function()
				require("Comment").setup()
			end,
		},
	},
	-- LuaSnip Options
	luasnip = {
		-- Add paths for including more VS Code style snippets in luasnip
		vscode_snippet_paths = {},
		-- Extend filetypes
		filetype_extend = {
			javascript = { "javascriptreact" },
		},
	},
	-- Modify which-key registration
	["which-key"] = {
		-- Add bindings
		register_mappings = {
			-- first key is the mode, n == normal mode
			n = {
				-- second key is the prefix, <leader> prefixes
				["<leader>"] = {},
			},
		},
	},
	-- CMP Source Priorities
	-- modify here the priorities of default cmp sources
	-- higher value == higher priority
	-- The value can also be set to a boolean for disabling default sources:
	-- false == disabled
	-- true == 1000
	cmp = {
		source_priority = {
			copilot = 1200,
			nvim_lsp = 1000,
			luasnip = 750,
			buffer = 500,
			path = 250,
		},
	},
	-- NeoTree configuration
	["neo-tree"] = require("neo-tree").setup({
		close_if_last_window = true,
		popup_border_style = "rounded",
		enable_git_status = true,
		enable_diagnostics = false,
		default_component_configs = {
			indent = {
				indent_size = 2,
				padding = 0,
				with_markers = true,
				indent_marker = "│",
				last_indent_marker = "└",
				highlight = "NeoTreeIndentMarker",
				with_expanders = false,
				expander_collapsed = "",
				expander_expanded = "",
				expander_highlight = "NeoTreeExpander",
			},
			icon = {
				folder_closed = "",
				folder_open = "",
				folder_empty = "",
				default = "",
			},
			name = {
				trailing_slash = false,
				use_git_status_colors = true,
			},
			git_status = {
				symbols = {
					added = "",
					deleted = "",
					modified = "",
					renamed = "➜",
					untracked = "★",
					ignored = "◌",
					unstaged = "✗",
					staged = "✓",
					conflict = "",
				},
			},
		},
		window = {
			position = "left",
			width = 25,
			mappings = {
				["<2-LeftMouse>"] = "open",
				["<cr>"] = "open",
				["o"] = "open",
				["S"] = "open_split",
				["s"] = "open_vsplit",
				["C"] = "close_node",
				["<bs>"] = "navigate_up",
				["."] = "set_root",
				["H"] = "toggle_hidden",
				["R"] = "refresh",
				["/"] = "fuzzy_finder",
				["f"] = "filter_on_submit",
				["<c-x>"] = "clear_filter",
				["a"] = "add",
				["d"] = "delete",
				["r"] = "rename",
				["y"] = "copy_to_clipboard",
				["x"] = "cut_to_clipboard",
				["p"] = "paste_from_clipboard",
				["c"] = "copy",
				["m"] = "move",
				["q"] = "close_window",
			},
		},
		nesting_rules = {},
		filesystem = {
			filtered_items = {
				visible = false,
				hide_dotfiles = true,
				hide_gitignored = false,
				hide_by_name = {
					".DS_Store",
					"thumbs.db",
					"node_modules",
					"__pycache__",
				},
				always_show = {
					".github",
					"terraform.tfvars",
					"variables.tf",
				},
			},
			follow_current_file = true,
			hijack_netrw_behavior = "open_current",
			use_libuv_file_watcher = true,
		},
		buffers = {
			show_unloaded = true,
			window = {
				mappings = {
					["bd"] = "buffer_delete",
				},
			},
		},
		git_status = {
			window = {
				position = "float",
				mappings = {
					["A"] = "git_add_all",
					["gu"] = "git_unstage_file",
					["ga"] = "git_add_file",
					["gr"] = "git_revert_file",
					["gc"] = "git_commit",
					["gp"] = "git_push",
					["gg"] = "git_commit_and_push",
				},
			},
		},
		event_handlers = {
			{
				event = "vim_buffer_enter",
				handler = function(_)
					if vim.bo.filetype == "neo-tree" then
						vim.wo.signcolumn = "auto"
					end
				end,
			},
		},
	}),
	-- Extend LSP configuration
	lsp = {
		skip_setup = { "tsserver" },
		-- enable servers that you already have installed without lsp-installer
		servers = {},
		-- add to the server on_attach function
		-- on_attach = function(client)
		-- do something
		-- end,

		-- override the lsp installer server-registration function
		-- server_registration = function(server, opts)
		--   require("lspconfig")[server].setup(opts)
		-- end,

		-- Add overrides for LSP server settings, the keys are the name of the server
		["server-settings"] = {},
	},
	-- Diagnostics configuration (for vim.diagnostics.config({}))
	diagnostics = {
		virtual_text = true,
		underline = true,
	},
	-- This function is run last
	-- good place to configure mappings and vim options
	polish = function()
		-- Set key bindings
		vim.keymap.set("n", "<C-s>", ":w!<CR>", { desc = "Save file" })
		vim.keymap.set("n", "<leader>o", "o<Esc>k", { desc = "Insert line below" })
		vim.keymap.set("n", "<leader>O", "O<Esc>j", { desc = "Insert line above" })
		vim.keymap.set({ "n", "v" }, "<leader>yj", "y'>o<Esc>p", { desc = "Duplicate line(s) down" })
		vim.keymap.set({ "n", "v" }, "<leader>yk", "y'>O<Esc>p", { desc = "Duplicate line(s) up" })
		vim.keymap.set("n", "<leader>kh", "<cmd>Neotree toggle<cr>", { desc = "Toggle Explorer" })
		vim.keymap.set("n", "<leader>kH", "<cmd>Neotree focus<cr>", { desc = "Focus Explorer" })

		vim.keymap.set("n", "gh", function()
			vim.diagnostic.open_float()
		end, { desc = "Floating diagnostics" })
		-- for spectre
		vim.keymap.set("n", "<leader>fs", function()
			require("spectre").open()
		end, { desc = "Open Spectre (find/replace)" })
		-- search current word
		vim.keymap.set("n", "<leader>sw", function()
			require("spectre").open_visual({ select_word = true })
		end, { desc = "Find/replace with selected word" })
		-- Set autocommands
		vim.api.nvim_create_augroup("packer_conf", { clear = true })

		vim.api.nvim_create_autocmd("BufWritePost", {
			desc = "Sync packer after modifying plugins.lua",
			group = "packer_conf",
			pattern = "plugins.lua",
			command = "source <afile> | PackerSync",
		})

		vim.keymap.del("n", "<leader>q")

		vim.keymap.set("n", "<leader>q", function()
			vim.lsp.buf.code_action()
		end, { desc = "Quick fix / code action" })

		local function alpha_on_bye(cmd)
			local bufs = vim.fn.getbufinfo({ buflisted = true })
			vim.cmd(cmd)
			if require("core.utils").is_available("alpha-nvim") and not bufs[2] then
				require("alpha").start(true)
			end
		end

		vim.keymap.del("n", "<leader>c")
		if require("core.utils").is_available("bufdelete.nvim") then
			vim.keymap.set("n", "<leader>x", function()
				alpha_on_bye("Bdelete!")
			end, { desc = "Close buffer" })
		else
			vim.keymap.set("n", "<leader>x", function()
				alpha_on_bye("bdelete!")
			end, { desc = "Close buffer" })
		end

		-- vim.keymap.del("n", "<leader>lr")
		vim.keymap.set("n", "<leader>rs", function()
			vim.lsp.buf.rename()
		end, { desc = "Rename symbol" })

		vim.keymap.set("n", "<leader>rf", function()
			vim.lsp.util.rename()
		end, { desc = "Rename file" })

		vim.keymap.set("n", "<C-p>", function()
			require("telescope.builtin").find_files()
		end, { desc = "Search files" })
		-- vim.keymap.set("n", "<leader>r", function()
		-- vim.lsp.buf.rename()
		-- end, { desc = "Rename current symbol" })
		-- Set up custom filetypes
		-- vim.filetype.add {
		--   extension = {
		--     foo = "fooscript",
		--   },
		--   filename = {
		--     ["Foofile"] = "fooscript",
		--   },
		--   pattern = {
		--     ["~/%.config/foo/.*"] = "fooscript",
		--   },
		--
		-- }
	end,
}

return config
