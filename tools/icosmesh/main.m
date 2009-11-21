/*	icosmesh
	
	Tool to generate subdivided icosahedron mesh data.
*/

#import <stdio.h>
#import "icosmesh.h"
#import "JAIcosTriangle.h"
#import "JAVertexSet.h"
#import "JAIcosMesh.h"


#define kFileName	"OOPlanetData"

#define kLevels		6


/*	Coordinates of icosahedron with poles on the Y axis.
	Based on http://www.csee.umbc.edu/~squire/reference/polyhedra.shtml#icosahedron
*/
static const Vector kBaseVertices[12] =
{
	{ +0.000000000000, +1.000000000000, +0.000000000000 },
	{ +0.894427200187, +0.447213577125, +0.000000000000 },
	{ +0.276393205089, +0.447213577125, +0.850650817090 },
	{ -0.723606805183, +0.447213577125, +0.525731117519 },
	{ -0.723606805183, +0.447213577125, -0.525731117519 },
	{ +0.276393205089, +0.447213577125, -0.850650817090 },
	{ +0.723606805183, -0.447213577125, +0.525731117519 },
	{ -0.276393205089, -0.447213577125, +0.850650817090 },
	{ -0.894427200187, -0.447213577125, +0.000000000000 },
	{ -0.276393205089, -0.447213577125, -0.850650817090 },
	{ +0.723606805183, -0.447213577125, -0.525731117519 },
	{ +0.000000000000, -1.000000000000, +0.000000000000 }
};


#define kBaseFaceCount 20
static const struct { unsigned a, b, c; } kBaseTriangles[kBaseFaceCount] =
{
	{ 0, 1, 2 },
	{ 0, 2, 3 },
	{ 0, 3, 4 },
	{ 0, 4, 5 },
	{ 0, 5, 1 },
	{ 11, 6, 7 },
	{ 11, 7, 8 },
	{ 11, 8, 9 },
	{ 11, 9, 10 },
	{ 11, 10, 6 },
	{ 1, 2, 6 },
	{ 2, 3, 7 },
	{ 3, 4, 8 },
	{ 4, 5, 9 },
	{ 5, 1, 10 },
	{ 6, 7, 2 },
	{ 7, 8, 3 },
	{ 8, 9, 4 },
	{ 9, 10, 5 },
	{ 10, 6, 1 }
};


static NSArray *SubdivideMesh(NSArray *triangles);

static void WritePrelude(FILE *header, FILE *source);
static void WriteVertices(FILE *header, FILE *source, JAVertexSet *vertices);
static void WriteMeshForTriangles(FILE *source, unsigned level, NSArray *triangles, JAVertexSet *vertices, unsigned *faceCount, unsigned *maxVertex);
static void WriteMesh(FILE *source, unsigned level, JAIcosMesh *mesh);


int main (int argc, const char * argv[])
{
	FILE *header = fopen(kFileName ".h", "w");
	FILE *source = fopen(kFileName ".c", "w");
	if (header == NULL || source == NULL)
	{
		fprintf(stderr, "Failed to open output files.\n");
		return EXIT_FAILURE;
	}
	
	WritePrelude(header, source);
	
	// Load up the base triangles.
	unsigned i;
	NSMutableArray *baseTriangles = [NSMutableArray arrayWithCapacity:kBaseFaceCount];
	for (i = 0; i < kBaseFaceCount; i++)
	{
		Vector a = kBaseVertices[kBaseTriangles[i].a];
		Vector b = kBaseVertices[kBaseTriangles[i].b];
		Vector c = kBaseVertices[kBaseTriangles[i].c];
		
	//	printf("%g %g %g   %g %g %g   %g %g %g\n", a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z);
		
		JAIcosTriangle *tri = [JAIcosTriangle triangleWithVectorA:a b:b c:c];
		[baseTriangles addObject:tri];
	}
	
	unsigned faceCount[kLevels];
	unsigned maxIndex[kLevels];
	JAVertexSet *vertices = [[JAVertexSet alloc] init];
	WriteMeshForTriangles(source, 0, baseTriangles, vertices, &faceCount[0], &maxIndex[0]);
	NSArray *triangles = baseTriangles;
	
	for (i = 1; i < kLevels; i++)
	{
		triangles = (NSMutableArray *)SubdivideMesh(triangles);
		WriteMeshForTriangles(source, i, triangles, vertices, &faceCount[i], &maxIndex[i]);
	}
	
	WriteVertices(header, source, vertices);
	
	fprintf(source, "\n\nconst OOPlanetDataLevel kPlanetData[kOOPlanetDataLevels] =\n{\n");
	for (i = 0; i < kLevels; i++)
	{
		if (i != 0)  fprintf(source, ",\n");
		fprintf(source, "\t%u, %u, kFaceIndicesLevel%u", maxIndex[i], faceCount[i], i);
	}
	fprintf(source, "\n};\n");
	
	fclose(header);
	fclose(source);
	
	return EXIT_SUCCESS;
}


static NSArray *SubdivideMesh(NSArray *triangles)
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:triangles.count * 4];
	
	for (JAIcosTriangle *triangle in triangles)
	{
		[result addObjectsFromArray:[triangle subdivide]];
	}
	
	return result;
}


static void WritePrelude(FILE *header, FILE *source)
{
	fprintf(header,
			"/*\n"
			"\t%s.h\n"
			"\tFor Oolite\n"
			"\t\n"
			"\tThis file was automatically generated by tools/icosmesh. Do not modify.\n"
			"\t\n"
			"\tThis data may be used freely.\n"
			"*/\n"
			"\n"
			"#import \"OOOpenGL.h\"\n"
			"\n"
			"\n"
			"#define kOOPlanetDataLevels %u\n"
			"\n"
			"\n"
			"typedef struct\n"
			"{\n"
			"\tunsigned        vertexCount;\n"
			"\tunsigned        faceCount;\n"
			"\tconst GLuint    *indices;   // faceCount * 3\n"
			"} OOPlanetDataLevel;\n"
			"\n"
			"\n"
			"extern const OOPlanetDataLevel kPlanetData[kOOPlanetDataLevels];\n", kFileName, kLevels);
	
	fprintf(source,
			"/*\n"
			"\t%s.c\n"
			"\tFor Oolite\n"
			"\t\n"
			"\tThis file was automatically generated by tools/icosmesh. Do not modify.\n"
			"\t\n"
			"\tThis data may be used freely.\n"
			"*/\n"
			"\n"
			"#include \"OOPlanetData.h\"\n", kFileName);
}


static void WriteVertices(FILE *header, FILE *source, JAVertexSet *vertices)
{
	unsigned i, count = vertices.count;
	
	fprintf(header, "\n\nextern const GLfloat kOOPlanetVertices[%u];\n", count * 3);
	fprintf(header, "\nextern const GLfloat kOOPlanetTexCoords[%u];\n", count * 2);
	
	fprintf(source, "\n\n/*  Shared vertex array\n    %u vertices\n*/\nconst GLfloat kOOPlanetVertices[%u] =\n{\n", count, count * 3);
	NSArray *data = [vertices positionArray];
	for (i = 0; i < count; i++)
	{
		if (i != 0)  fprintf(source, ",\n");
		fprintf(source, "\t%+.8ff, %+.8ff, %+.8ff", [[data objectAtIndex:i * 3] doubleValue], [[data objectAtIndex:i * 3 + 1] doubleValue], [[data objectAtIndex:i * 3 + 2] doubleValue]);
	}
	
	fprintf(source, "\n};\n\n/*  Shared texture coordinate array\n    %u pairs\n*/\nconst GLfloat kOOPlanetTexCoords[%u] =\n{\n", count, count * 2);
	data = [vertices texCoordArray];
	for (i = 0; i < count; i++)
	{
		if (i != 0)  fprintf(source, ",\n");
		fprintf(source, "\t%+.8ff, %+.8ff", [[data objectAtIndex:i * 2] doubleValue], [[data objectAtIndex:i * 2 + 1] doubleValue]);
	}
	
	fprintf(source, "\n};\n");
}


static void WriteMeshForTriangles(FILE *source, unsigned level, NSArray *triangles, JAVertexSet *vertices, unsigned *faceCount, unsigned *maxVertex)
{
	JAIcosMesh *mesh = [JAIcosMesh meshWithVertexSet:vertices];
	[mesh addTriangles:triangles];
	WriteMesh(source, level, mesh);
	
	*faceCount = mesh.faceCount;
	*maxVertex = mesh.maxIndex + 1;
}


static void WriteMesh(FILE *source, unsigned level, JAIcosMesh *mesh)
{
	unsigned i, count = mesh.faceCount;
	NSArray *indices = [mesh indexArray];
	
	fprintf(source, "\n\n/*  Level %u index array\n    %u faces\n*/\nstatic const GLuint kFaceIndicesLevel%u[%u] =\n{\n", level, count, level, count * 3);
	for (i = 0; i < count; i++)
	{
		if (i != 0)  fprintf(source, ",\n");
		fprintf(source, "\t%5u, %5u, %5u", [[indices objectAtIndex:i * 3] unsignedIntValue], [[indices objectAtIndex:i * 3 + 1] unsignedIntValue], [[indices objectAtIndex:i * 3 + 2] unsignedIntValue]);
	}
	fprintf(source, "\n};\n");
}


//	Convert vector to latitude and longitude (or θ and φ).
void VectorToCoordsRad(Vector v, double *latitude, double *longitude)
{
	v = VectorNormal(v);
	
	double las = v.y;
	if (las != 1.0f)
	{
		double lat = asin(las);
		double rlac = 1.0 / sqrt(1.0 - las * las);	// Equivalent to abs(1/cos(lat))
		
		if (latitude != NULL)  *latitude = lat;
		if (longitude != NULL)
		{
			double los = v.x * rlac;
			double lon = asin(fmin(1.0, fmax(-1.0, los)));
			
			// Quadrant rectification.
			if (v.z < 0.0f)
			{
				// We're beyond 90 degrees of longitude in some direction.
				if (v.x < 0.0f)
				{
					// ...specifically, west.
					lon = -M_PI - lon;
				}
				else
				{
					// ...specifically, east.
					lon = M_PI - lon;
				}
			}
			
			*longitude = lon;
		}
	}
	else
	{
		// Straight up, avoid divide-by-zero
		if (latitude != NULL)  *latitude = M_PI / 2.0f;
		if (longitude != NULL)  *longitude = 0.0f;	// arbitrary
	}
}


void VectorToCoords0_1(Vector v, double *latitude, double *longitude)
{
	VectorToCoordsRad(v, latitude, longitude);
	if (latitude != NULL) *latitude = 1.0 - (*latitude / M_PI + 0.5);
	if (longitude != NULL) *longitude = 1.0 - (*longitude / (M_PI * 2.0) + 0.5);
}
