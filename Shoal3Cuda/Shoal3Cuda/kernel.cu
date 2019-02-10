
#pragma region Includes

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "device_functions.h"
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/copy.h>

#include <string>
#include <cstdio>
#include <iterator>
#include <iostream>
#include <random>
#include <chrono>
#include <memory>
#include <functional>
#include<cuda.h>
#include<cuda_runtime.h>
#include <gl/glew.h>
#include <gl/GL.h>
#include <gl/freeglut.h>
#include <utility>  

#pragma comment(lib, "glew32.lib")
#include <iostream>
#include <ctime>
#include <Windows.h>
#include<device_launch_parameters.h>
#include <algorithm>
#pragma endregion
using namespace std;
using namespace thrust;
#define LEN 1000


#pragma region Structures
struct Position {
	float x;
	float y;
	float z;
};
struct Color {
	int r;
	int g;
	int b;
	int a;
};
struct Sphere
{
	int r;
	Position position;
	Color color;
};
enum Operation
{
	Sum = 0,
	Mul = 1,
	Diff = 2,
	None = 3
};
struct Line {
	Sphere* in;
	float inPosition;
	Sphere* out;
	float outPosition;

};
struct Node {
	Operation operation;
	Sphere* sphere;
	Node* left = NULL;
	Node* right = NULL;
	Node* parent = NULL;
	thrust::device_vector<Line*> lines[LEN * LEN];
};
unsigned char *data;
#pragma endregion
#pragma region CUDA

__host__ __device__
float getAngle(float x1, float y1, float x2, float y2) {
	float value = x1 * x2 + y1 * y2;
	value = value != 0 ? value / sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2)) : 0;
	return 180 - atan2(-y1, x1) * 57.0;
}
__host__ __device__
float vectorMultiply(float x1, float y1, float x2, float y2) {
	float value = x1 * x2 + y1 * y2;
	value = value != 0 ? value / sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2)) : 0;
	return value;
}
__host__ __device__
float getVectorLength(float x1, float y1, float x2, float y2) {
	return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
}
#pragma endregion
#pragma region  Helpers
Position* crossMultiply(Position* v1, Position* v2) {
	// [ a2 * b3 - a3 * b2, a3 * b1 - a1 * b3, a1 * b2 - a2 * b1 ]
	Position* newP = new Position();
	newP->x = v1->y * v2->z - v1->z * v2->y;
	newP->y = v1->z * v2->x - v1->x * v2->z;
	newP->z = v1->x * v2->y - v1->y * v2->x;
	return newP;
}
float dotMultiply(Position* v1, Position* v2) {
	return v1->x * v2->x + v1->y * v2->y + v1->z * v2->z;
}
unsigned char* prepareData() {
	unsigned char *data = new unsigned char[LEN * LEN * 4];
	for (int i = 0; i < LEN * LEN * 4; i++) {
		data[i] = 0;
	}

	return data;
}
Position* DiffPoints(Position* p1, Position* p2) {
	Position* p3 = new Position();
	p3->x = p1->x - p2->x;
	p3->y = p1->y - p2->y;
	p3->z = p1->z - p2->z;
	return p3;
}
Position* DividePoint(Position* p, float a) {
	Position* newP = new Position();
	newP->x = p->x / a;
	newP->y = p->y / a;
	newP->z = p->z / a;
	return newP;
}
Position* SumPoints(Position* p1, Position* p2) {
	Position* newP = new Position();
	newP->x = p1->x + p2->x;
	newP->y = p1->y + p2->y;
	newP->z = p1->z + p2->z;
	return newP;
}
Position* MulPoints(Position* p, float a) {
	Position* newP = new Position();
	newP->x = p->x * a;
	newP->y = p->y * a;
	newP->z = p->z *a;
	return newP;
}
float lengthBetweenTwoPoints(Position* p1, Position* p2) {
	return sqrt(pow(p1->x - p2->x, 2) + pow(p1->x - p2->y, 2) + pow(p1->z - p2->z, 2));
}
float vectorLength(Position* p) {
	return sqrt(pow(p->x, 2) + pow(p->y, 2) + pow(p->z, 2));
}
__host__ __device__
void setInd(unsigned char *data, int i, int value) {
	data[i * 4] = value;
	data[i * 4 + 1] = value;
	data[i * 4 + 2] = value;
	data[i * 4 + 3] = 255;
}
#pragma endregion
#pragma region Logic operations
vector<Line*> MulOperation(vector<Line*> lines1, vector<Line*> lines2) {
	vector<Line*> ret;
	return ret;
}
vector<Line*> SumOperation(vector<Line*> lines1, vector<Line*> lines2) {
	vector<Line*> ret;
	Line* last = lines1[lines1.size() - 1] < lines2[lines2.size() - 1] ? lines2[lines2.size() - 1] : lines1[lines1.size() - 1];
	while (ret.size() == 0 || ret[ret.size() - 1] != last) {

	}
	return ret;
}
vector<Line*> DiffOperation(vector<Line*> lines, vector<Line*> line3) {
	vector<Line*> ret;
	return ret;
}
#pragma endregion
#pragma region Engine
__host__ __device__
Line* countLine(Sphere* sphere, Position* camera, Position* place) {
	Position* v = DiffPoints(place, camera);
	Position* dv = DiffPoints(camera, &sphere->position);
	float a = dotMultiply(v, v);
	float b = 2 * dotMultiply(v, dv);
	float c = dotMultiply(dv, dv) - pow(sphere->r, 2);

	Line* ret = new Line();
	ret->in = sphere;
	ret->out = sphere;
	//Range result = { false, 0,0, sphere_id };

	float delta = b * b - 4 * a*c;

	if (delta < 0)
		return NULL;
	else
	{
		if (delta == 0)
		{
			float t = -b / (2 * a);
			ret->inPosition = t;
			ret->outPosition = t;
		}
		else
		{
			float sdelta = sqrt(delta);
			float t1 = (-b + sdelta) / (2 * a);
			float t2 = (-b - sdelta) / (2 * a);
			if (t1 < t2)
			{
				ret->inPosition = t1;
				ret->outPosition = t2;
			}
			else
			{
				ret->inPosition = t2;
				ret->outPosition = t1;
			}
		}
	}
	ret->inPosition = ret->inPosition < 0 ? ret->inPosition * -100 : ret->inPosition * 100;
	ret->outPosition = ret->outPosition < 0 ? ret->outPosition * -100 : ret->outPosition * 100;
	return ret;

}
__host__ __device__
void concatTwoNodes(Node* ret) {
	Node* left = ret->left;
	Node* right = ret->right;

	for (int i = 0; i < LEN * LEN; i++) {
		ret->lines[i].insert(ret->lines[i].end(), right->lines[i].begin(), right->lines[i].end());
		ret->lines[i].insert(ret->lines[i].end(), left->lines[i].begin(), left->lines[i].end());
	}
}
__device__
void DrawElement(Node* node, Position* camera, unsigned char *data, int i) {
	if (node->left != NULL) {
		DrawElement(node->left, camera, data, i);
	}
	if (node->right != NULL) {
		DrawElement(node->right, camera, data, i);
	}
	if (node->sphere == NULL) {
		concatTwoNodes(node);
	} else {
		Position* place = new Position();
		place->x = i % LEN;
		place->y = i;
		while (place->y >= LEN) place->y -= LEN;
		place->z = 0;
		Line* sphereLine = countLine(node->sphere, camera, place);
		if (sphereLine != NULL) {
			node->lines[i].push_back(sphereLine);
		}
	}
	if (node->parent == NULL) {
		setInd(data, i, node->lines[i].size() > 0 ? 1 : 0);
		//glDrawPixels(LEN, LEN, GL_RGBA, GL_UNSIGNED_BYTE, data);
	}
}
#pragma endregion
#pragma region THREE

__device__
Sphere* setSpherePosition(Sphere* sphere, int x, int y, int z) {
	sphere->position.x = x;
	sphere->position.y = y;
	sphere->position.z = z;
	return sphere;
}
__device__
Sphere* setSphereColor(Sphere* sphere, int r, int g, int b, int a) {
	sphere->color.r = r;
	sphere->color.g = g;
	sphere->color.b = b;
	sphere->color.a = a;
	return sphere;
}
__device__
Node* CreateRoot() {
	Node* root = new Node();
	root->parent = NULL;
	root->operation = Sum;

	Sphere* sphere1 = new Sphere();
	sphere1->r = 50;
	sphere1 = setSpherePosition(sphere1, 100, 100, 0);
	sphere1 = setSphereColor(sphere1, 255, 0, 255, 255);

	Sphere* sphere3 = new Sphere();
	sphere3->r = 70;
	sphere3 = setSpherePosition(sphere3, 150, 150, 0);
	sphere3 = setSphereColor(sphere3, 0, 255, 0, 255);

	Sphere* sphere2 = new Sphere();
	sphere2->r = 100;
	sphere2 = setSpherePosition(sphere2, 170, 140, 0);
	sphere2 = setSphereColor(sphere2, 0, 0, 255, 255);

	Sphere* sphere4 = new Sphere();
	sphere4->r = 120;
	sphere4 = setSpherePosition(sphere4, 200, 200, -50);
	sphere4 = setSphereColor(sphere4, 100, 100, 100, 255);

	Node* left1 = new Node();
	left1->operation = Diff;
	left1->parent = root;

	Node* right2 = new Node();
	right2->operation = None;
	right2->sphere = sphere2;
	right2->parent = left1;

	Node* left2 = new Node();
	left2->operation = Sum;
	left2->parent = left1;

	left1->right = right2;
	left1->left = left2;

	Node* right3 = new Node();
	right3->operation = None;
	right3->sphere = sphere4;
	right3->parent = left2;

	Node* left3 = new Node();
	left3->operation = None;
	left3->sphere = sphere3;
	left3->parent = left2;

	left2->left = left3;
	left2->right = right3;

	Node* right = new Node();
	right->sphere = sphere1;
	right->operation = None;
	right->parent = root;

	root->right = right;
	root->left = left1;
	return root;
}
#pragma endregion
#pragma region Render
void renderCpu() {
}
void initializeGPU() {
	//cudaError_t error = cudaSuccess;
	////size_t spheresSize = 4 * sizeof(Sphere);
	//size_t nodeSize = 8 * sizeof(Node);
	//size_t dataSize = 4 * LEN * LEN * sizeof(char);

	//error = cudaMalloc((void**)&)
}
__global__
void DrawElements(Position* camera, unsigned char *data) {

	const long numThreads = blockDim.x * gridDim.x;
	const long threadID = blockIdx.x * blockDim.x + threadIdx.x;

	Node* root = CreateRoot();

	int i = threadID;
	if (threadID < LEN * LEN) {
		DrawElement(root, camera, data, i);
	}

}
void renderGpu()
{
	cudaError_t error = cudaSuccess;
	int pictureSize = LEN * LEN;
	size_t dataSize = 4 * pictureSize * sizeof(char);
	int threadsPerBlock = 256;

	Position* camera = new Position();
	camera->x = 0;
	camera->y = 0;
	camera->z = 1000;

	DrawElements << < 1024, 1024 >> > (camera, prepareData());
	
}
void render()
{
	glClearColor(0.0 / 255.0, 0.0 / 255.0, 0.0 / 225.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	//DrawElement(root, prepareData(), camera);


	renderGpu();
	//renderCpu();
	glutSwapBuffers();
	//glutPostRedisplay();
}
#pragma endregion
int main(int argc, char* argv[])
{
	// Initialize GLUTx
	glutInit(&argc, argv);
	// Set up some memory buffers for our display
	glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE);
	// Set the window size
	glutInitWindowSize(LEN, LEN);
	// Create the window with the title "Hello,GL"
	glutCreateWindow("CSGThree");
	glutDisplayFunc(render);
	glutMainLoop();

	GLenum err = glewInit();
	if (GLEW_OK != err) {
		fprintf(stderr, "GLEW error");
		return 1;
	}

	return 0;
}