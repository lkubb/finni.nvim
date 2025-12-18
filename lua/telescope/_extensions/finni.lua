return require("telescope").register_extension({
  setup = require("finni.pickers.telescope").setup,
  exports = {
    manual = require("finni.pickers.telescope").manual_picker,
    auto_all = require("finni.pickers.telescope").auto_all_picker,
    auto = require("finni.pickers.telescope").auto_picker,
    project = require("finni.pickers.telescope").project_picker,
  },
})
