#!/usr/bin/env python

################################################################################
#
# consolidate.py
#
# Version: 1.000
#
# Author: Gwynne Reddick, Luxology
#
#   Copyright (c) 2001-2017, The Foundry Group LLC
#   All Rights Reserved. Patents granted and pending.
#
#
#
################################################################################

import os
from shutil import copy2, copytree

dirs = {'images':'imported_images',
        'ies':'imported_ies',
        'seq':'imported_imgseq',
        'mdd':'imported_mdd'}

channel = {'images':'filename',
           'ies':'filename',
           'seq':'pattern',
           'mdd':'file'}

seqmessage = 'This scene uses externally linked image sequences,\nsave to scene directory?'
refsmessage = 'This scene uses external scene references,\nmerge these references?'


def savefile(title, type, save_ext, path=None):
    lx.eval('query hostservice server.name ? saver/%s' % type)
    filetype = lx.eval('query hostservice server.infoTag ? saver.outClass').split(' ', 1)[0]
    lx.eval("dialog.setup fileSave")
    lx.eval("dialog.title {%s}" % (title))
    lx.eval("dialog.fileType {%s}" % (filetype))
    lx.eval("dialog.fileSaveFormat {%s}" % save_ext)

    if path != None:
        lx.eval('dialog.result {%s}' % path)
    try:
        lx.eval("dialog.open")
        return lx.eval("dialog.result ?")
    except:
        return None


def yesnodialog(title, message):
    lx.eval('dialog.setup yesNo')
    lx.eval('dialog.title {%s}' % title)
    lx.eval('dialog.msg {%s}' % message)
    try:
        lx.eval('dialog.open')
        return lx.eval('dialog.result ?')
    except:
        return None


def hasrefs():
    try:
        numitems = lx.eval('query sceneservice item.N ? all')
        for x in range(numitems):
            refpath = lx.eval('query sceneservice item.refPath ? %s' % x)
            if refpath and '.lxo' in refpath:
                return True
    except:
        exc_log()


def isref(id):
    refpath = lx.eval('query sceneservice item.refPath ? {%s}' % id)
    if refpath and '.lxo' in refpath:
        return True


def copyfiles(type, items):
    try:
        outdir = os.path.join(basepath, dirs[type])
        if not os.path.isdir(outdir):
            os.mkdir(outdir)
        for item in items:
            if isref(item) and not merge:
                continue
            lx.eval('query sceneservice item.ID ? {%s}' % item)
            srcpath = lx.eval('item.channel %s ? item:{%s}' % (channel[type], item))
            if not basepath in srcpath:
                srcdir, fname = os.path.split(srcpath)
                if type == 'seq':
                    outdir = os.path.join(outdir, os.path.split(srcdir)[1])
                    if not os.path.isdir(outdir):
                        copytree(srcdir, outdir)
                    newpath = os.path.join(outdir, fname)
                else:
                    newpath = os.path.join(outdir, fname)
                    if not os.path.isfile(newpath):
                        copy2(srcpath, newpath)
                try:
                    lx.eval('!!item.channel {%s} {%s} item:{%s}' % (channel[type], newpath, item))
                except:
                    pass
    except:
        exc_log()


def exc_log():
    lx.out('Exception "%s" on line: %d' % (sys.exc_value, sys.exc_traceback.tb_lineno))


###-- Script body
try:
    merge = False
    # get the base path for the scene directory which is the project folder
    # if a project is defined or the directory containing the scene if not
    basepath = lx.eval('query platformservice path.path ? project')
    scene = lx.eval('query sceneservice scene.file ? current')
    if scene:
        scenedir, scenefile = os.path.split(scene)
    if not scene:
        scene = savefile('Save Scene', '$LXOB', 'lxo')
        if scene:
            try:
                lx.eval('scene.saveAs "%s" $LXOB false' % scene)
            except:
                exc_log()
    if scene and not basepath:
        scenedir, scenefile = os.path.split(scene)
        basepath = os.path.dirname(scene)

    # If we've got a base path, carry on with copying assets
    if basepath:
        # Check for scene refs
        if hasrefs():
            merge = yesnodialog('Merge Scene Refs', refsmessage)

        # sort clips into images and sequences
        images = []
        seqs = []
        clips = lx.evalN('query layerservice clips ? all')
        for clip in clips:
            id = lx.eval('query layerservice clip.id ? %s' % clip)
            if 'videoStill' in id:
                images.append(id)
            if 'videoSequence' in id:
                seqs.append(id)

        # copy images
        if images:
            copyfiles('images', images)

        # copy image sequences
        if seqs and yesnodialog('Save Image Sequences', seqmessage):
            copyfiles('seq', seqs)

        # copy ies lights
        ies = []
        numIES = lx.eval('query sceneservice photometryLight.N ? all')
        for x in range(numIES):
            id = lx.eval('query sceneservice photometryLight.ID ? %s' % x)
            ies.append(id)
        if ies:
            copyfiles('ies', ies)

        # copy mdd files
        mdds = []
        num_mdds = lx.eval('query sceneservice deformMDD.N ? all')
        for x in range(num_mdds):
            id = lx.eval('query sceneservice deformMDD.ID ? %s' % x)
            mdds.append(id)
        if mdds:
            copyfiles('mdd', mdds)

        if merge:
            prefsState = lx.eval('pref.value export.mergsRefs ?')
            lx.eval('pref.value export.mergsRefs 1')
        scenefile = '%s_bundled.lxo' % os.path.splitext(scenefile)[0]
        sceneout = os.path.join(scenedir, scenefile)
        lx.eval('scene.saveAs {%s} $LXOB false' % sceneout)
        if merge:
            lx.eval('pref.value export.mergsRefs %s' % prefsState)
            lx.eval('!!scene.close')
            lx.eval('scene.open {%s} normal' % sceneout)

except:
    exc_log()

