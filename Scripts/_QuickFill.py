#!/usr/bin/python

#QuickFill --> fill your container with another mesh

#Author Keith Sheppard
#AUG2014

#HOW TO
#1 - Save the code into a text file and name it to WHATEVER_YOU_WANT.py
#2 - Put the file in the modo scripts directory
#3 - Only two meshes are required - Prototype mesh + Bucket mesh
#4 - Select the prototype mesh
#4 - run the script
#5 - answer the question - how many ?
#6 - rerun to keep filling - remember to select your prototype first
#7 - enjoy


import lx
import sys

bln_True = 1
bln_False = 0
intAdviseUser = 0
strAll ="all"
strSelected ="selected"

def fn_CheckLayerVisibility():
    intTotalLayers = lx.evalN("query layerservice layers ? {%s}" % strAll)

    for EachLayer in intTotalLayers:
        strLayerItem_ID = lx.eval("query layerservice layer.ID ? {%s}" % EachLayer)
        blnLayerVisibility = lx.eval("layer.setVisibility {%s} ?" % strLayerItem_ID)
        if blnLayerVisibility == 0:
            lx.eval("layer.setVisibility {%s} 1" % strLayerItem_ID)

def fn_CheckSingleMeshSelect():
    global intLayerIndex
    global strLayer_Name
    global strLayer_ID
    global intTotalMeshes
    #//make sure only one mesh is selected
    intTotalMeshes = lx.eval("query layerservice layer.n ? {%s}" % strAll)
    #lx.out(intTotalMeshes)

    if intTotalMeshes != 2:
        fn_UserAdvisory(3)
        sys.exit()
    elif intTotalMeshes == 2:
        intLayers_Selected = lx.eval("query layerservice layer.n ? fg")
        #lx.out(intModoMeshSelected)
        if intLayers_Selected != 1:
            fn_UserAdvisory(1)
            sys.exit()
    intLayerIndex = lx.eval("query layerservice layer.index ? current")
    #lx.out(intLayerIndex)
    strLayer_Name = lx.eval("query layerservice layer.name ? current")
    #lx.out(strLayer_Name)
    strLayer_ID = lx.eval("query layerservice layer.ID ? current")
    #lx.out(strLayer_ID)

def fn_SetTheSubItem():
    global intSubLayerIndex
    global strSubLayer_Name
    global strSubLayer_ID
    intSubLayerIndex = lx.eval("query layerservice layer.index ? bg")
    #lx.out(intSubLayerIndex)
    strSubLayer_Name = lx.eval("query layerservice layer.name ? bg")
    #lx.out(strSubLayer_Name)
    strSubLayer_ID = lx.eval("query layerservice layer.ID ? bg")
    #lx.out(strSubLayer_ID)

def fn_CheckMeshPolyCount():
    global strNoPolyMesh

    All_Layers = lx.evalN("query layerservice layers ? {%s}" % strAll)

    for EachLayer in All_Layers:
        strNoPolyMesh =  lx.eval("query layerservice layer.name ? {%s}" % EachLayer)
        intMeshPolyCount = lx.eval("query layerservice poly.N ? {%s}" % strAll)
        #lx.out(intMeshPolyCount)
        if intMeshPolyCount < 1:
            fn_UserAdvisory(2)
            sys.exit()

def fn_SelectTheMesh():
    lx.eval("select.Item item:{%s} mode: set" % strLayer_ID)

def fn_SelectTheSubMesh():
    lx.eval("select.Item item:{%s} mode: set" % strSubLayer_ID)

def fn_SelDel_TheSolver():
    All_Items = lx.eval("query sceneservice item.N ? ")
    #lx.out(All_Items)
    for EachItem in range(All_Items):
        strItemName =  lx.eval("query sceneservice item.name ? {%s}" % EachItem)
        #lx.out(strItemName)
        strItem_ID =  lx.eval("query sceneservice item.ID ? {%s}" % EachItem)
        #lx.out(strItem_ID)
        strItemType = lx.eval("query sceneservice item.typeLabel ? {%s}" % EachItem)
        #lx.out(strItemType)
        if strItemType == "solver":
            lx.eval("select.drop item")
            lx.eval("select.item {%s}" % strItemName)
            lx.eval("item.delete")

def fn_SetSolverAttributes():
    strItem_ID = lx.eval("query sceneservice item.ID ? {solver}")
    strItemName =  lx.eval("query sceneservice item.name ? {%s}" % strItem_ID)
    lx.eval("select.drop item")
    lx.eval("select.item {%s}" % strItemName)
    lx.eval("item.channel physicsRate 160")
    lx.eval("item.channel gravity.Y -2.0")

def fn_StartClean():
    #ensure all is dropped/cleared
    lx.eval("tool.set Transform {%s}" % bln_False)
    lx.eval("tool.set TransformScale {%s}" % bln_False)
    lx.eval("tool.set TransformMove {%s}" % bln_False)
    lx.eval("tool.set TransformRotate {%s}" % bln_False)
    lx.eval("select.drop center")
    lx.eval("select.drop pivot")
    lx.eval("select.drop item")
    lx.eval("select.drop polygon")
    lx.eval("select.drop edge")
    lx.eval("select.drop vertex")
    if lx.eval("tool.clearTask ? ") != "":
        strClearTask = lx.eval("tool.clearTask ? ")
        lx.eval("tool.clearTask {%s}" % strClearTask)

def fn_UserAdvisory(intAdviseUser):

    if intAdviseUser == 1:
        strMsgTitle = "Mesh/Prototype Selection"
        strMsgContent = "Please select only one mesh item as your prototype, then run the script again!"
    elif intAdviseUser == 2:
        strMsgTitle = "GeoCount"
        strMsgContent = "The item (%s), does not contain any geometry. The script operation will end!" % strNoPolyMesh
    elif intAdviseUser == 3:
        strMsgTitle = "Mesh Count"
        strMsgContent = "Two Meshes are required! {%s} mesh(es) are found. Please make the necessary adjustments and rerun the script " % intTotalMeshes
    else:
        strMsgTitle = "Script Completed Successfully"
        strMsgContent = "Enjoy !"

    lx.eval("dialog.setup info")
    lx.eval("dialog.title {%s}" % strMsgTitle)
    lx.eval("dialog.msg {%s}" % strMsgContent)
    lx.eval("dialog.open")
    sys.exit()

def fn_UserInputs(intQuestionAsk):

    global varQuestionResponse
    if intQuestionAsk == 1:
        strQ_Variable = "qAskValue"
        strQ_Type = "username"
        strQuestion = "Enter Prototype Quantity"
    elif intQuestionAsk == 2:
        strQ_Variable = "Choices"
        strQ_Type = "list"
        strQuestion = "Yes;No"

    try:
        if not lx.eval("query scriptsysservice userValue.isDefined ? {%s}" % strQ_Variable):
            lx.eval("!user.defNew {%s} type:integer life:momentary " % strQ_Variable)
        lx.eval("!user.def {%s} {%s} {%s}" % (strQ_Variable, strQ_Type, strQuestion))
        lx.eval("?user.value {%s}" % strQ_Variable)
        varQuestionResponse = lx.eval("user.value {%s} ?" % strQ_Variable)

    except:
        sys.exit()

def fn_CenterBoundingBox():
    lx.eval("select.type item")
    lx.eval("center.bbox center")
    #and return it to poly mode
    lx.eval("select.type polygon")

def fn_MakeDynamic(intD_Type):
    #lx.out(intD_Type)
    lx.eval("item.removePackage dynamics")
    lx.eval("dynamics.makeDynamic {%s}" % intD_Type)
    lx.eval("item.channel reCollisionShape mesh")

    if intD_Type == 0:
        lx.eval("item.channel reStatic {%s}" % bln_False)
        lx.eval("item.channel reBounce 0.15")
        lx.eval("item.channel reMargin 0.00001")
        lx.eval("item.channel reFriction 0.0")
        lx.eval("item.channel reMassSource localMass")
        lx.eval("item.channel reMass 5.0")

    else:
        lx.eval("item.channel reStatic {%s}" % bln_True)
        lx.eval("item.channel reBounce 0.00")
        lx.eval("item.channel reMargin 0.00001")
        lx.eval("item.channel reFriction 0.0")

def fn_CycleAndCreate():
    for varProtoTypes in range(0,varQuestionResponse):
        fn_StartClean()
        fn_SelectTheMesh()
        lx.eval("simulate 0.0 5.0 0.0")
        lx.eval("select.time 5.0 0 0")
        lx.eval("select.type polygon")
        lx.eval("select.invert")
        lx.eval("copy")
        fn_SelectTheSubMesh()
        lx.eval("select.type polygon")
        lx.eval("paste")
        lx.eval("select.time 0 0 0")


def fn_SetModoMode():
    lx.eval("select.type polygon")

#Script Start
fn_UserInputs(1)
fn_CheckLayerVisibility()
fn_CheckSingleMeshSelect()
fn_SetTheSubItem()
fn_CheckMeshPolyCount()
fn_StartClean()
fn_SelDel_TheSolver()
fn_SelectTheMesh()
fn_CenterBoundingBox()
fn_MakeDynamic(0)
fn_StartClean()
fn_SelectTheSubMesh()
fn_CenterBoundingBox()
fn_MakeDynamic(4)
fn_SetSolverAttributes()
fn_CycleAndCreate()
fn_SetModoMode()
fn_UserAdvisory(0)

#Done
#send any questions to keith dot sheppard at bell dot net
#cheers


