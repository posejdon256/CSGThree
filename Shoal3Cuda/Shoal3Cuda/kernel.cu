

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "device_functions.h"

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

using namespace std;

#define LEN 1000


struct Sphere
{
	int r;
	int positionX;
	int positionY;
};
enum Operation
{
	Sum = 0,
	Mul = 1,
	Diff = 2,
	None = 3
};
struct node {
	Operation operation;
	Sphere* sphere;
	node* left = NULL;
	node* right = NULL;
	node* parent = NULL;
};
struct zLen {
	bool isIn;
	float pos;
};
node * root;
unsigned char *data;

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

__global__
void updateShoalGpu(float *d_arrayOfFishes) {
	const long numThreads = blockDim.x * gridDim.x;
	const long threadID = blockIdx.x * blockDim.x + threadIdx.x;
	int i = threadID;
}
vector<zLen*>* prepareZetsArray() {
	vector<zLen*> *zlenth = new vector<zLen*>[LEN * LEN];
	for (int i = 0; i < LEN * LEN; i++) {
		zlenth = new vector<zLen*>();
	}
	return zlenth;
}
bool sortFunction(zLen* i, zLen* j) { return i->pos > j->pos; }
unsigned char* prepareData() {
	unsigned char *data = new unsigned char[LEN * LEN * 4];
	for (int i = 0; i < LEN * LEN * 4; i++) {
		data[i] = 0;
	}

	return data;
}
void changeViewPort(int w, int h)
{
	glViewport(0, 0, w, h);
}

void renderTriangle() {

	glColor3f(255.0 / 255.0, 204.0 / 255.0, 0.0 / 255.0);

	glVertex3f(-0.75, 0.5, 0.0);
	glVertex3f(1.0, 0.0, 0.0);
	glVertex3f(1.0, 1.0, 0.0);

}

void renderShoal() {
}
void renderGpu()
{
}
float getZet(int x, int y, int cenX, int cenY, int r) {
	return sqrt(pow(r, 2) - pow(x - cenX, 2) - pow(y - cenY, 2));
}
float zetDist(int x, int y, int cenX, int cenY, int r) {
	return  max(((200.0f - getZet(x, y, cenX, cenY, r)) / 500.0f) * 255.0f, 0.0f);
}
float zetDistBack(int x, int y, int cenX, int cenY, int r) {
	return  min(((200.0f + getZet(x, y, cenX, cenY, r)) / 500.0f) * 255.0f, 255.0f);
}
bool isInCircle(int x, int y, int cenX, int cenY, int r) {
	float len = sqrt(pow(x - cenX, 2) + pow(y - cenY, 2));
	return len <= r;
}
void setInd(unsigned char *data, int i, int j, int value) {
	data[((i + 500) * LEN + (j + 500)) * 4] = value;
	data[((i + 500) * LEN + (j + 500)) * 4 + 1] = value;
	data[((i + 500) * LEN + (j + 500)) * 4 + 2] = value;
	data[((i + 500) * LEN + (j + 500)) * 4 + 3] = value;
}
float getMinimumOfArray(vector<float> arr) {
	if (arr.size() == 0) {
		return 0;
	}
	float minimum = INFINITY;
	for (int i = 0; i < arr.size(); i++) {
		minimum = minimum < arr[i] ? minimum : arr[i];
	}
	return minimum;
}
bool sortByMulValue(pair<int, float> first, pair<int, float> second) {
	return first.second < second.second;
}
float getMultiplyValue(vector<float> arr) {
	if (arr.size() < 4) {
		return 0;
	}
	vector<pair<int, float>> _arr;
	for (int i = 0; i < 4; i++) {
		pair<int, float> elem(floor(i / 2), arr[i]);
		_arr.push_back(elem);
	}
	sort(_arr.begin(), _arr.end(), sortByMulValue);
	if (_arr[0].first != _arr[1].first) {
		return _arr[1].second;
	}
	return 0;
}
float getDifferenceValue(vector<float> arr, int id) {
	if (arr.size() < 2) {
		return 0;
	}
	vector<pair<int, float>> _arr;
	for (int i = 0; i < arr.size(); i++) {
		pair<int, float> elem(floor(i / 2), arr[i]);
		_arr.push_back(elem);
	}
	sort(_arr.begin(), _arr.end(), sortByMulValue);
	if (_arr.size() == 2 && id == 0) {
		return _arr[0].second;
	}
	else if (id == 1 && _arr.size() == 2) {
		return 0;
	}
	if (_arr[0].first == 0) {
		return _arr[0].second;
	}
	return _arr[2].second;
}
int getMinimum(Sphere* left, Sphere* right, bool X) {
	if (left == NULL || right == NULL) {
		return 0;
	}
	return X ? min(left->positionX - left->r, right->positionX - right->r) : min(left->positionY - left->r, right->positionY - right->r);
}
int getMaximum(Sphere* left, Sphere* right, bool X) {
	if (left == NULL || right == NULL) {
		return 0;
	}
	return X ? max(left->positionX + left->r, right->positionX + right->r) : max(left->positionY + left->r, right->positionY + right->r);
}
bool isCloseEnough(Sphere* sphere, int i, int j) {
	return sqrt(pow(sphere->positionX - i, 2) + pow(sphere->positionY - j, 2)) < sphere->r;
}
void DrawElement(node* Node, unsigned char *data, vector<zLen*>* zlength) {
	if (Node->operation == None) return;
	if (Node->operation != None) {
		DrawElement(Node->left, data, zlength);
	}
	if (Node->operation != None) {
		DrawElement(Node->right, data, zlength);
	}
	Sphere* left = Node->left->sphere;
	Sphere* right = Node->right->sphere;


	int minimumX = getMinimum(left, right, true);
	int maximumX = getMaximum(left, right, true);
	int minimumY = getMinimum(left, right, false);
	int maximumY = getMaximum(left, right, false);
	for (int i = minimumX; i < maximumX; i++) {
		for (int j = minimumY; j < maximumY; j++) {
			vector<float> distances;
			int _dist = 0;
			if (left != NULL && isCloseEnough(left, i, j)) {
				distances.push_back(zetDist(i, j, left->positionX, left->positionY, left->r));
				distances.push_back(zetDistBack(i, j, left->positionX, left->positionY, left->r));
			}
			if (right != NULL && isCloseEnough(right, i, j)) {
				_dist = 1;
				distances.push_back(zetDist(i, j, right->positionX, right->positionY, right->r));
				distances.push_back(zetDistBack(i, j, right->positionX, right->positionY, right->r));
			}
			if (Node->operation == Sum) {
				setInd(data, i, j, getMinimumOfArray(distances));
			}
			else if (Node->operation == Mul) {
				setInd(data, i, j, getMultiplyValue(distances));
			}
			else { // Diff
				setInd(data, i, j, getDifferenceValue(distances, _dist));
			}
		}
	}
	glDrawPixels(LEN, LEN, GL_RGBA, GL_UNSIGNED_BYTE, data);
}
void CreateRoot() {
	root = new node();
	root->operation = Sum;

	Sphere* sphere1 = new Sphere();
	sphere1->r = 200;
	sphere1->positionX = 100;
	sphere1->positionY = 100;

	Sphere* sphere3 = new Sphere();
	sphere3->r = 100;
	sphere3->positionX = -50;
	sphere3->positionY = -50;

	Sphere* sphere2 = new Sphere();
	sphere2->r = 100;
	sphere2->positionX = -120;
	sphere2->positionY = -120;

	Sphere* sphere4 = new Sphere();
	sphere4->r = 50;
	sphere4->positionX = 50;
	sphere4->positionY = -50;

	node* left1 = new node();
	left1->operation = Diff;
	left1->parent = root;

	node* right2 = new node();
	right2->operation = None;
	right2->sphere = sphere2;
	right2->parent = left1;

	node* left2 = new node();
	left2->operation = Sum;
	left2->parent = left1;

	left1->right = right2;
	left1->left = left2;

	node* right3 = new node();
	right3->operation = None;
	right3->sphere = sphere4;
	right3->parent = left2;

	node* left3 = new node();
	left3->operation = None;
	left3->sphere = sphere3;
	left3->parent = left2;

	left2->left = left3;
	left2->right = right3;

	node* right = new node();
	right->sphere = sphere1;
	right->operation = None;
	right->parent = root;
	root->right = right;
	root->left = left1;
}
void render()
{
	glClearColor(0.0 / 255.0, 0.0 / 255.0, 0.0 / 225.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	DrawElement(root, prepareData(), prepareZetsArray());


	renderGpu();
	renderShoal();
	glutSwapBuffers();
	//glutPostRedisplay();
}
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
	CreateRoot();
	glutDisplayFunc(render);
	glutMainLoop();

	GLenum err = glewInit();
	if (GLEW_OK != err) {
		fprintf(stderr, "GLEW error");
		return 1;
	}

	return 0;
}