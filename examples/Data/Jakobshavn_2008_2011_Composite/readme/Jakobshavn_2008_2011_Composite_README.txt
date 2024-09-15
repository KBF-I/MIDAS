CReSIS Gridded Data Product README 
-----------------------------------------------------------------

Version Date: 01-Jun-2012 
Contact: cresis_data@cresis.ku.edu 

Location: Greenland 
GlacierName: Jakobshavn_2008_2011_Composite 
Projection: WGS_84_NSIDC_Sea_Ice_Polar_Sterographic_North 

SoftwareUsed: ESRI ArcGIS 10 (ArcInfo) 
SoftwareUsed: MATLAB R2010b 

ProductsIncluded: Flightlines 
ProductsIncluded: Errors 
ProductsIncluded: Boundaries 
ProductsIncluded: Grids 
ProductsIncluded: PreviewImages 

Flightline Details: 
-----------------------------------
- ESRI Shapefile and TXT of all data points used 
- A_SURF and A_BED are the variables used to interpolate. 
- NASA ATM data is used, if it exists. See variable "Data_Type" 
- ICESat data is used, if it exists for IceFree Areas. See variable "Data_Type" 
- Flightlines are clipped to a 10km buffer of the boundary (Study Area) 

Error Details: 
-----------------------------------
- Results of Crossover Analysis 
- Note: Crossovers Are corrected season by season, not across season.
        Errors present are across, not within season.
- CSV File of Crossover Analysis Results 
- MAT File of Crossover Analysis Results 
- TXT File of Statistics from Crossover Analysis Results 
- PNG Preview Image of Crossover Analysis Results 

Boundary Details: 
-----------------------------------
- ESRI Shapefile of "Study Area" extent 

Grid Details: 
-----------------------------------
- Surface interpolated using IDW interpolation in ArcGIS 
- Bottom interpolated using TopoToRaster interpolation in ArcGIS 
   Note: Any bottom past the grounding line represents ice bottom not ocean bottom. 
- Thickness is calculated using Surface minus Bottom (above) in ArcGIS 
- ASCII rasters for Surface,Thickness,and Bed Elevation are provided 
- An XYZ TXT File containing data from all grids is also provided 

GridNoDataValue: -9999 
GridCellSize: 500 x 500m 

PreviewImage Details: 
-----------------------------------
- PNG maps of Flightlines,Surface,Thickness,and Bed Elevation 

Other Information: 
-----------------------------------
- If NASA ATM data exists for a season, ATM Surface is used. (Data_Type) 
- To read ASCII grids use Conversion > ASCIItoRaster in ArcGIS. 
- To read ASCII grids use arcgridread.m in MATLAB(Mapping). 
- To read SHP files use shaperead.m in MATLAB(Mapping) 

Citing and Acknowledgements : 
-----------------------------------
External Data Used:

NASA ATM LIDAR
IceBridge ATM L2 Icessn Elevation, Slope, and Roughness
http://nsidc.org/data/docs/daac/icebridge/ilatm2/index.html

ICESAT DEM
DiMarzio, J., A. Brenner, R. Schutz, C. A. Shuman, and H. J. Zwally. 2007. GLAS/ICESat 1 km laser altimetry digital elevation model of Greenland. Boulder, Colorado USA: National Snow and Ice Data Center. Digital media.
IceFree Mask
Howat I.M and A. Negrete, in prep, A high-resolution ice mask for the Greenland Ice Sheet and peripheral glaciers and icecaps.

Whenever the data are used, please include the following acknowledgement:

We acknowledge the use of data and/or data products from CReSIS generated with
support from NSF grant ANT-0424589 and NASA grant NNX10AT68G

Please cite data according to NSIDC standard

