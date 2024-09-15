import os.path
import numpy as np
from collections import OrderedDict

def contourlevelzero(md,mask,level):
    """CONTOURLEVELZERO - figure out the zero level (or offset thereof, specified by the level value)
                       of a vectorial mask, and vectorialize it into an exp or shp compatible structure.
    
       Usage:
          contours=contourlevelzero(md,mask,level)
    
       See also: PLOT_CONTOUR
    """
    
    #process data 
    if md.mesh.dimension()==3:
        x = md.mesh.x2d
        y = md.mesh.y2d
        z=md.mesh.z
        index=md.mesh.elements2d-1
    else:
        x=md.mesh.x
        y=md.mesh.y
        index=md.mesh.elements-1
        z=np.zeros((md.mesh.numberofvertices,1))
        
    if len(mask)==0:
        raise OSError("mask provided is empty")
    
    if md.mesh.dimension()==3:
        if len(mask)!=md.mesh.numberofvertices2d: 
            raise OSError("mask provided should be specified at the vertices of the mesh")
    else:
        if len(mask)!=md.mesh.numberofvertices:
            raise OSError("mask provided should be specified at the vertices of the mesh")
        
    #initialization of some variables
    numberofelements=np.size(index,0)
    elementslist=np.c_[0:numberofelements]
    c=[]
    h=[]
    
    #get unique edges in mesh
    #1: list of edges
    edges=np.vstack((np.vstack((index[:,(0,1)],index[:,(1,2)])),index[:,(2,0)]))

    #2: find unique edges
    [edges,J]=np.unique(np.sort(edges,1),axis=0,return_inverse=True)
    #3: unique edge numbers
    vec=J
    #4: unique edges numbers in each triangle (2 triangles sharing the same edge will have
    #   the same edge number)
    edges_tria=np.hstack((np.hstack((vec[elementslist],vec[elementslist+numberofelements])),vec[elementslist+2*numberofelements]))
    
    #segments [nodes1 nodes2]
    Seg1=index[:,(0,1)]
    Seg2=index[:,(1,2)]
    Seg3=index[:,(2,0)]
    
    #segment numbers [1;4;6;...]
    Seg1_num=edges_tria[:,0]
    Seg2_num=edges_tria[:,1]
    Seg3_num=edges_tria[:,2]
    
    #value of data on each tips of the segments
    Data1=mask[Seg1]
    Data2=mask[Seg2]
    Data3=mask[Seg3]
    
    #get the ranges for each segment
    Range1=np.sort(Data1,1)
    Range2=np.sort(Data2,1)
    Range3=np.sort(Data3,1)
    
    #find the segments that contain this value
    pos1=(Range1[:,0]<level) & (Range1[:,1]>=level)
    pos2=(Range2[:,0]<level) & (Range2[:,1]>=level)
    pos3=(Range3[:,0]<level) & (Range3[:,1]>=level)
    
    #get elements
    poselem12=(pos1) & (pos2)
    poselem13=(pos1) & (pos3)
    poselem23=(pos2) & (pos3)
    poselem=np.where((poselem12) | (poselem13) | (poselem23))
    poselem=poselem[0]
    numelems=len(poselem)
    
    #if no element has been flagged, skip to the next level
    if numelems==0:
        raise Exception('contourlevelzero warning message: no elements found with corresponding level value in mask')
        contours=[]
        return contours
    
    #go through the elements and build the coordinates for each segment (1 by element)
    x1=np.zeros((numelems,1))
    x2=np.zeros((numelems,1))
    y1=np.zeros((numelems,1))
    y2=np.zeros((numelems,1))
    z1=np.zeros((numelems,1))
    z2=np.zeros((numelems,1))
    
    edge_l=np.zeros((numelems,2))
    
    for j in range(0,numelems):
        
        with np.errstate(divide='ignore', invalid='ignore'):
            weight1=np.divide(level-Data1[poselem[j],0],Data1[poselem[j],1]-Data1[poselem[j],0])
            weight2=np.divide(level-Data2[poselem[j],0],Data2[poselem[j],1]-Data2[poselem[j],0])
            weight3=np.divide(level-Data3[poselem[j],0],Data3[poselem[j],1]-Data3[poselem[j],0])
        
        if poselem12[poselem[j]]==True:
            
            x1[j]=x[Seg1[poselem[j],0]]+weight1*[x[Seg1[poselem[j],1]]-x[Seg1[poselem[j],0]]]
            x2[j]=x[Seg2[poselem[j],0]]+weight2*[x[Seg2[poselem[j],1]]-x[Seg2[poselem[j],0]]]
            y1[j]=y[Seg1[poselem[j],0]]+weight1*[y[Seg1[poselem[j],1]]-y[Seg1[poselem[j],0]]]
            y2[j]=y[Seg2[poselem[j],0]]+weight2*[y[Seg2[poselem[j],1]]-y[Seg2[poselem[j],0]]]
            z1[j]=z[Seg1[poselem[j],0]]+weight1*[z[Seg1[poselem[j],1]]-z[Seg1[poselem[j],0]]]
            z2[j]=z[Seg2[poselem[j],0]]+weight2*[z[Seg2[poselem[j],1]]-z[Seg2[poselem[j],0]]]
            
            edge_l[j,0]=Seg1_num[poselem[j]]
            edge_l[j,1]=Seg2_num[poselem[j]]
        elif poselem13[poselem[j]]==True:
            
            x1[j]=x[Seg1[poselem[j],0]]+weight1*[x[Seg1[poselem[j],1]]-x[Seg1[poselem[j],0]]]
            x2[j]=x[Seg3[poselem[j],0]]+weight3*[x[Seg3[poselem[j],1]]-x[Seg3[poselem[j],0]]]
            y1[j]=y[Seg1[poselem[j],0]]+weight1*[y[Seg1[poselem[j],1]]-y[Seg1[poselem[j],0]]]
            y2[j]=y[Seg3[poselem[j],0]]+weight3*[y[Seg3[poselem[j],1]]-y[Seg3[poselem[j],0]]]
            z1[j]=z[Seg1[poselem[j],0]]+weight1*[z[Seg1[poselem[j],1]]-z[Seg1[poselem[j],0]]]
            z2[j]=z[Seg3[poselem[j],0]]+weight3*[z[Seg3[poselem[j],1]]-z[Seg3[poselem[j],0]]]
            
            edge_l[j,0]=Seg1_num[poselem[j]]
            edge_l[j,1]=Seg3_num[poselem[j]]
        elif poselem23[poselem[j]]==True:
            
            x1[j]=x[Seg2[poselem[j],0]]+weight2*[x[Seg2[poselem[j],1]]-x[Seg2[poselem[j],0]]]
            x2[j]=x[Seg3[poselem[j],0]]+weight3*[x[Seg3[poselem[j],1]]-x[Seg3[poselem[j],0]]]
            y1[j]=y[Seg2[poselem[j],0]]+weight2*[y[Seg2[poselem[j],1]]-y[Seg2[poselem[j],0]]]
            y2[j]=y[Seg3[poselem[j],0]]+weight3*[y[Seg3[poselem[j],1]]-y[Seg3[poselem[j],0]]]
            z1[j]=z[Seg2[poselem[j],0]]+weight2*[z[Seg2[poselem[j],1]]-z[Seg2[poselem[j],0]]]
            z2[j]=z[Seg3[poselem[j],0]]+weight3*[z[Seg3[poselem[j],1]]-z[Seg3[poselem[j],0]]]

            edge_l[j,0]=Seg2_num[poselem[j]]
            edge_l[j,1]=Seg3_num[poselem[j]]

        #else:
	    #it shoud not go here
            
    #now that we have the segments, we must try to connect them...
    
    #loop over the subcontours
    contours=[]
    
    while len(edge_l)>0:
        
        #take the right edge of the second segment and connect it to the next segments if any
        e1=edge_l[0,0]
        e2=edge_l[0,1]
        xc=np.vstack((x1[0],x2[0]))
        yc=np.vstack((y1[0],y2[0]))
        zc=np.vstack((z1[0],z2[0]))
        #erase the lines corresponding to this edge
        edge_l=np.delete(edge_l,0,axis=0)
        x1=np.delete(x1,0,axis=0)
        x2=np.delete(x2,0,axis=0)
        y1=np.delete(y1,0,axis=0)
        y2=np.delete(y2,0,axis=0)
        z1=np.delete(z1,0,axis=0)
        z2=np.delete(z2,0,axis=0)
        pos1=np.where(edge_l==e1)
        
        while len(pos1[0])>0:
            
            if np.all(pos1[1]==0):
                xc=np.vstack((x2[pos1[0]],xc))
                yc=np.vstack((y2[pos1[0]],yc))
                zc=np.vstack((z2[pos1[0]],zc))
                #next edge:
                e1=edge_l[pos1[0],1]
            else:
                xc=np.vstack((x1[pos1[0]],xc))
                yc=np.vstack((y1[pos1[0]],yc))
                zc=np.vstack((z1[pos1[0]],zc))
                #next edge:
                e1=edge_l[pos1[0],0]
                
            #erase the lines of this
            edge_l=np.delete(edge_l,pos1[0],axis=0)
            x1=np.delete(x1,pos1[0],axis=0)
            x2=np.delete(x2,pos1[0],axis=0)
            y1=np.delete(y1,pos1[0],axis=0)
            y2=np.delete(y2,pos1[0],axis=0)
            z1=np.delete(z1,pos1[0],axis=0)
            z2=np.delete(z2,pos1[0],axis=0)
            #next connection
            pos1=np.where(edge_l==e1)
            
        #same thing the other way (to the right)
        pos2=np.where(edge_l==e2)

        while len(pos2[0])>0:
            
            if np.all(pos2[1]==0):
                xc=np.vstack((xc,x2[pos2[0]]))
                yc=np.vstack((yc,y2[pos2[0]]))
                zc=np.vstack((zc,z2[pos2[0]]))
                #next edge:
                e2=edge_l[pos2[0],1]
            else:
                xc=np.vstack((xc,x1[pos2[0]]))
                yc=np.vstack((yc,y1[pos2[0]]))
                zc=np.vstack((zc,z1[pos2[0]]))
                #next edge:
                e2=edge_l[pos2[0],0]
                
            #erase the lines of this
            edge_l=np.delete(edge_l,pos2[0],axis=0)
            x1=np.delete(x1,pos2[0],axis=0)
            x2=np.delete(x2,pos2[0],axis=0)
            y1=np.delete(y1,pos2[0],axis=0)
            y2=np.delete(y2,pos2[0],axis=0)
            z1=np.delete(z1,pos2[0],axis=0)
            z2=np.delete(z2,pos2[0],axis=0)
            #next connection
            pos2=np.where(edge_l==e2)
            
        #save xc,yc contour: 
        newcontour = OrderedDict()
        newcontour['nods'] = np.size(xc)
        newcontour['density'] = 1 
        newcontour['closed'] = 0
        newcontour['x'] = np.ma.filled(xc.astype(float), np.nan)
        newcontour['y'] = np.ma.filled(yc.astype(float), np.nan)
        newcontour['z'] = np.ma.filled(zc.astype(float), np.nan)
        newcontour['name'] = ''
        contours.append(newcontour)
        
    return contours
