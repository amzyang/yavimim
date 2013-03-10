# -*- coding: utf-8 -*-
import vim


def yavimim_status():
    buffer_iminsert = int(vim.eval("&l:iminsert"))
    if buffer_iminsert != 1:
        contents = "EN"
    else:
        traditional = int(vim.eval("g:yavimim_traditional"))
        sim_cht = '繁' if traditional else '简'
        im = vim.eval('yavimim#backend#getim()')
        name = 'name_cht' if traditional else 'name'
        contents = im[name] + "." + sim_cht
    return [{'contents': contents, "highlight_group": ['yavimim_status']}]
# vim: tabstop=4 expandtab shiftwidth=4 softtabstop=4 textwidth=79
