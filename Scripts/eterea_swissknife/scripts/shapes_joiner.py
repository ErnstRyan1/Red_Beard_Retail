#python

#Shapes Joiner. 
#Questo script date delle forme 2d in un unico livello le fonde insieme in modo da render semplice la loro fusione o sottrazione. Le forme originali non vengono cancellate. Le forme possono anche essere non complanari o leggermente ruotate, lo script funzionerà lo stesso.
#Autore Gianni Soldati. www.giannisoldati.com
#versione 0.1 del 07/10/2012. Primo rilascio
#versione 0.2 del 05/11/2012. Modificato per lavorare anche con una workplane personalizzata. Però le forme fuse non vengono create sulla workplane. Hanno un lieve offset.
#versione 0.3 del 25/01/2015. Aggiunto un reset dei segmenti del comando cube altrimenti ricorda i segmenti dell'ultimo comando cube usato.

#Inizializzo le liste
BBSize = [0,0,0]
BBCen = [0,0,0]

BBox = lx.evalN("query layerservice layer.bounds ? selected")

# Dimensione e centro del rettangolo su cui proietterò le forme iniziali
BBSize[0] = (BBox[3] - BBox[0]) * 2
BBSize[1] = (BBox[4] - BBox[1]) * 2
BBSize[2] = (BBox[5] - BBox[2]) * 2
BBCen[0] = (BBox[3] + BBox[0]) / 2
BBCen[1] = (BBox[4] + BBox[1]) / 2
BBCen[2] = (BBox[5] + BBox[2]) / 2

#lx.out("Le dimensioni in X,Y,Z sono ", str(BBSize[0]), str(BBSize[1]), str(BBSize[2]))
#lx.out("Il centro di trova in ", str(BBCen[0]), str(BBCen[1]), str(BBCen[2]))

# Cerco quale dimensione è minore nelle forme perchè mi dirà secondo quale asse proiettare e posso anche assicurarmi di creare un rettangolo e non un parallepipedo se le forme non sono complanari
DimMin = min(BBSize[0],BBSize[1],BBSize[2])

if DimMin == BBSize[0]:
	Asse = "x"
	BBSize[0] = 0
if DimMin == BBSize[1]:
	Asse = "y"
	BBSize[1] = 0
if DimMin == BBSize[2]:
	Asse = "z"
	BBSize[2] = 0

#Creo un nuovo livello
lx.eval ("layer.new")
lx.eval ("item.name Shapes_Joined mesh")

#Creo il rettangolo
lx.eval ("tool.set prim.cube on")
lx.eval ("tool.reset")
lx.eval ("vertMap.new Texture txuv")
lx.eval ("tool.setAttr prim.cube cenX "+str(BBCen[0]))
lx.eval ("tool.setAttr prim.cube sizeX "+str(BBSize[0]))
lx.eval ("tool.setAttr prim.cube cenY "+str(BBCen[1]))
lx.eval ("tool.setAttr prim.cube sizeY "+str(BBSize[1]))
lx.eval ("tool.setAttr prim.cube cenZ "+str(BBCen[2]))
lx.eval ("tool.setAttr prim.cube sizeZ "+str(BBSize[2]))
lx.eval ("tool.doApply")

#Trovo l'indice del livello Shapes_joined per poi selezionare il poligono in eccesso
Indice = lx.eval ("query layerservice layer.index ? Shapes_Joined")
#lx.out("l'indice è "+str(Indice))

#Eseguo l'axys drill
lx.eval ("poly.drill slice "+str(Asse))
lx.eval ("tool.drop")

#Imposto modalità su polygons, seleziono il poligono di troppo e lo cancello
lx.eval ("select.typeFrom polygon;edge;vertex;item;pivot;center;ptag true")
lx.eval("select.element "+str(Indice)+" polygon set 0")
lx.eval("delete")