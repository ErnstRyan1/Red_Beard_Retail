#python
 
'''
 
    A simple command plugin to demonstrate performing a spherize
    operation on all points in the selected layer.
    
    To run the command, select at least one mesh layer and type "layer.spherize" into the command history.
    Note: As a custom command, the python source file needs to be placed in an 'lxserv' folder. 
    
    Author: Matt Cox
 
'''
 
import lx
import lxifc
import lxu.command
import lxu.select
import math
 
class Spherize_Cmd(lxu.command.BasicCommand):
    def __init__(self):
        lxu.command.BasicCommand.__init__(self)
        '''
            We want to have a single argument for this command. It will
            define the distance to push the geometry out by. This is an
            optional command and if it is undefined, we'll use a set distance
            of 1.0.
        '''
        self.dyna_Add('distance', lx.symbol.sTYPE_FLOAT)
        self.basic_SetFlags(0, lx.symbol.fCMDARG_OPTIONAL)
 
    def cmd_Flags(self):
        '''
            We also want to define some other flags for the command. Namely,
            fCMD_MODEL and fCMD_UNDO. This basically tells modo that we are
            performing an action that changes the internal state of the program,
            and the command should undoable/redoable.
        '''
        return lx.symbol.fCMD_MODEL | lx.symbol.fCMD_UNDO
 
    def basic_Enable(self, msg):
        '''
            We only want the command to be enabled if there is at least one mesh
            item selected. This is quite an easy test, we simply get a list
            of the current selected items and loop through them checking if they
            are a mesh item. As soon as we find a mesh, we return True. If we
            don't find a mesh, we return False.
        '''
        item_sel = lxu.select.ItemSelection()
        for i in range(0, len(item_sel.current())):
            '''
                Localize the current selected item.
            '''
            item_loc = lx.object.Item(item_sel.current()[i])
 
            '''
                Check that we actually have a localized item to work with.
            '''
            if item_loc.test() == False:
                continue
 
            '''
                Now we simply check if the item is a mesh or not, to do this,
                we need to query the SceneService for the Mesh item type and
                then check whether the current selection matches that type.
            '''
            scn_svc = lx.service.Scene()
            mesh_type = scn_svc.ItemTypeLookup(lx.symbol.sITYPE_MESH)
            if item_loc.TestType(mesh_type):
                return True
 
        '''
            We have been unable to find a mesh item, so we'll return False and
            disable the command. Ideally, we'd set a message for the user to
            tell them why the command is disabled.
        '''
        return False
 
 
    def basic_Execute(self, msg, flags):
        '''
            Here is where the "meat" of our command will go. Assuming that our
            command has passed the basic_Enable method, this function will be
            called to Execute our command.
        '''
 
        '''
            We want to get any arguments for the command, these are simply read
            by their index, in the order they are added to the constructor.
            As the only argument for this command is optional, we'll query
            whether it's Set, or whether we need to assume a default value.
        '''
        if self.dyna_IsSet(0) == True:
            target_dist = self.attr_GetFlt(0)
        else:
            target_dist = 1.0
 
        '''
            We'll be using the LayerService to interact with meshes in the
            scene. So the first step is to get a LayerService interface.
        '''
        layer_svc = lx.service.Layer()
 
        '''
            Now we want to iterate through the active layers. We do this
            using the LayerScan interface. We have to localize a LayerScan
            interface using the LayerService ScanAllocate method.
            The symbol "f_LAYERSCAN_EDIT_VERTS", tells modo that we want
            to scan active layers and edit the mesh. See the sdk wiki
            for the declaration of this symbol.
        '''
        layer_scan = lx.object.LayerScan(layer_svc.ScanAllocate(lx.symbol.f_LAYERSCAN_EDIT_VERTS))
 
        '''
            We'll just check that the LayerScan item localized correctly.
        '''
        if layer_scan.test() == False:
            return
 
        '''
            Now we simply want to iterrate through all the active layers and
            perform an operation on each of them. So we count the number of
            layers using the LayerScan interface and then loop through them.
        '''
        for n in range(0, layer_scan.Count()):
            '''
                Now we are on the current layer, we want to grab the mesh
                for the current layer. Then we can perform operations on it.
            '''
            mesh_loc = lx.object.Mesh(layer_scan.MeshEdit(n))
 
            '''
                As always, just confirm that we have correctly localized
                the mesh.
            '''
            if mesh_loc.test() == False:
                continue
 
            '''
                We also want to check that the point count is greater than
                zero. There's no real requirement to do this, but it makes
                things a little cleaner.
            '''
            if mesh_loc.PointCount() == 0:
                continue
 
            '''
                So that we can find the center of all the vertices, we'll simply
                get the bounding box of the mesh layer. The bounding box is defined
                by two vectors representing opposite corners of the bounding box.
                Once we have the bounding box, we calculate it's center.
            '''
            mesh_bounds = mesh_loc.BoundingBox(lx.symbol.iMARK_ANY)
            mesh_center = ((mesh_bounds[0][0]+mesh_bounds[1][0])/2,(mesh_bounds[0][1]+mesh_bounds[1][1])/2,(mesh_bounds[0][2]+mesh_bounds[1][2])/2)
 
            '''
                Here we want to iterate through all the points on the
                current mesh. Ideally, this would be done using a Visitor,
                but for simplicity sake in this example, we'll use a for loop.
            '''
            for i in range(0, mesh_loc.PointCount()):
                '''
                    Before we operate on the point, we need to localize the
                    point we want to work with.
                '''
                point_loc = lx.object.Point(mesh_loc.PointAccessor())
 
                '''
                    Yet again, we just double check that we have correctly
                    localized the point object, if we have then we select the
                    point we want to work with from its index.
                '''
                if point_loc.test() == False:
                    continue
 
                point_loc.SelectByIndex(i)
 
                '''
                    We'll simply get the point position and measure the distance
                    from the point to the mesh_center. We'll then divide the
                    target distance by the distance and then multiply the position
                    vector by the resulting calculation. This should move the point
                    to the desired distance along it's current vector.
                '''
                point_pos = point_loc.Pos()
                point_dist = math.sqrt(math.pow((point_pos[0]-mesh_center[0]),2)+math.pow((point_pos[1]-mesh_center[1]),2)+math.pow((point_pos[2]-mesh_center[2]),2))
 
                if point_dist == 0:
                    continue
 
                scale = target_dist / point_dist
                point_newPos = ((point_pos[0]*scale),(point_pos[1]*scale),(point_pos[2]*scale))
 
                '''
                    Now that we have calculated the new position, we want to set
                    the point position on the mesh.
                '''
                point_loc.SetPos(point_newPos)
 
            '''
                Before we move on to the next layer, we need to tell modo that we
                have made edits to this mesh.
            '''
            layer_scan.SetMeshChange(n, lx.symbol.f_MESHEDIT_POINTS)
 
        '''
            Finally, we need to call apply on the LayerScan interface. This tells
            modo to perform all the mesh edits.
        '''
        layer_scan.Apply()
 
'''
    "Blessing" the class promotes it to a fist class server. This basically
    means that modo will now recognize this plugin script as a command plugin.
'''
lx.bless(Spherize_Cmd, "layer.spherize")