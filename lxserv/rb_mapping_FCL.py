# python

import lx, lxifc, lxu.command

FORMS = [
    {
        "label":"Unit Switcher Pie Menu",
		"recommended": "Alt+7",
        "hash":"rb_unit_switcher:sheet"
    }, {
        "label":"Seletion Sets Pie Menu",
        "hash":"rb_select_set:sheet"
    }, {
        "label":"Packaging Thicken Pie Menu",
        "hash":"rb_packaging_thicken:sheet"
    }, {
        "label":"UV Unwrapping Pie Menu",
        "hash":"rb_uv_unwrapping:sheet"
    }
]

def list_commands():
    fcl = []
    for n, form in enumerate(sorted(FORMS, key=lambda k: k['label']) ):
        fcl.append("redbeard.labeledPopover {%s} {%s}" % (form["hash"], form["label"]))
        fcl.append("redbeard.labeledMapKey {%s} {%s}" % (form["hash"], form["label"]))

        if n < len(FORMS)-1:
            fcl.append('- ')

    return fcl


class CommandListClass(lxifc.UIValueHints):
    def __init__(self, items):
        self._items = items

    def uiv_Flags(self):
        return lx.symbol.fVALHINT_FORM_COMMAND_LIST

    def uiv_FormCommandListCount(self):
        return len(self._items)

    def uiv_FormCommandListByIndex(self,index):
        return self._items[index]


class CommandClass(lxu.command.BasicCommand):
    def __init__(self):
        lxu.command.BasicCommand.__init__(self)

        self.dyna_Add('query', lx.symbol.sTYPE_INTEGER)
        self.basic_SetFlags(0, lx.symbol.fCMDARG_QUERY)

    def arg_UIValueHints(self, index):
        if index == 0:
            return CommandListClass(list_commands())

    def cmd_Execute(self,flags):
        pass

    def cmd_Query(self,index,vaQuery):
        pass

lx.bless(CommandClass, "rb.mapping_FCL")
