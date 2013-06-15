# -*- coding: utf-8 -*-
import vim


def yavimim_status(pl):
    buffer_iminsert = int(vim.eval("&l:iminsert"))
    if buffer_iminsert != 1:
        return None
    else:
        traditional = int(vim.eval("g:yavimim_traditional"))
        sim_cht = u'繁' if traditional else u'简'
        key = 'name_cht' if traditional else 'name'
        name = vim.eval('yavimim#backend#getim()["%s"]' % key)
        contents = name.decode('utf8') + "." + sim_cht
    return [{'contents': contents, "highlight_group": ['yavimim_status']}]
# vim: tabstop=4 expandtab shiftwidth=4 softtabstop=4 textwidth=79
