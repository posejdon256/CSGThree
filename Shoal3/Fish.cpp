#include "Fish.h"
fish arrayOfFishes[100];

using namespace std;

void defineFishes() {
	int numberOfFishesInRow = 10;
	for (int i = 0; i < numberOfFishesInRow; i++) {
		for (int j = 0; j < numberOfFishesInRow; j++) {
			fish f;
			f.id = i * numberOfFishesInRow + j;
			f.dirX = - 1.0;
			f.dirY = 0.0;
			f.x = 0.9 + i * -0.2;
			f.y = 0.9 + j * -0.2;

			arrayOfFishes[i * numberOfFishesInRow + j] = f;
		}
	}
}
fish* getArrayOfFishes() {
	return arrayOfFishes;
}
void updateShoal() {
	for (int i = 0; i < 100; i++) {
		if (arrayOfFishes[i].x <= -0.9 && arrayOfFishes[i].dirX < 0) {
			arrayOfFishes[i].dirX = -arrayOfFishes[i].dirX;
			arrayOfFishes[i].x += arrayOfFishes[i].dirX * 0.01;
			arrayOfFishes[i].y += arrayOfFishes[i].dirY * 0.01;
			//arrayOfFishes[i].dirY = 1.0;
		}
		if (arrayOfFishes[i].x >= 0.9 && arrayOfFishes[i].dirX > 0) {
			arrayOfFishes[i].dirX = -arrayOfFishes[i].dirX;
			arrayOfFishes[i].x += arrayOfFishes[i].dirX * 0.01;
			arrayOfFishes[i].y += arrayOfFishes[i].dirY * 0.01;
			//arrayOfFishes[i].dirY = -1.0;
		}
		if (arrayOfFishes[i].y <= -0.9 && arrayOfFishes[i].dirY < 0) {
			//arrayOfFishes[i].dirX = -1.0;
			arrayOfFishes[i].dirY = -arrayOfFishes[i].dirY;
			arrayOfFishes[i].x += arrayOfFishes[i].dirX * 0.01;
			arrayOfFishes[i].y += arrayOfFishes[i].dirY * 0.01;
		}
		if (arrayOfFishes[i].y >= 0.9 && arrayOfFishes[i].dirY > 0) {
			//arrayOfFishes[i].dirX = 1.0;
			arrayOfFishes[i].dirY = -arrayOfFishes[i].dirY;
			arrayOfFishes[i].x += arrayOfFishes[i].dirX * 0.01;
			arrayOfFishes[i].y += arrayOfFishes[i].dirY * 0.01;
		}
		arrayOfFishes[i].x += arrayOfFishes[i].dirX * 0.005;
		arrayOfFishes[i].y += arrayOfFishes[i].dirY * 0.005;
	}
	int len = 10;
	for (int i = 0; i < len; i++) {
		for (int j = 0; j < len; j++) {
			int place = i * len + j;
			updateInNeighborhoud(i, j);
		}
	}
}
void updateInNeighborhoud(int x, int y) {
	int len = 10;
	float nei = 0.2;
	float neiClose = 0.1;
	vector<fish> friends;
	vector<fish> toClose;
	fish current = arrayOfFishes[x * len + y];
	for (int i = 0; i < len; i++) {
		for (int j = 0; j < len; j++) {
			fish sFish = arrayOfFishes[i * len + j];
			if (getVectorLength(sFish.x, sFish.y, current.x, current.y) < nei 
				&& current.id != sFish.id 
				&& vectorMultiply(sFish.x - current.x, sFish.y - current.y, current.dirX, current.dirY) > 0) {
				friends.push_back(sFish);
			}
			if (getVectorLength(sFish.x, sFish.y, current.x, current.y) < neiClose 
				&& current.id != sFish.id
				&& vectorMultiply(sFish.x - current.x, sFish.y - current.y, current.dirX, current.dirY) > 0) {
				toClose.push_back(sFish);
			}
		}
	}
	float dirXNew = 0.0;
	float posNewX = 0.0;
	float posNewY = 0.0;
	float dirYNew = 0.0;
	float awayFromX = 0.0;
	float awayFromY = 0.0;
	for (int i = 0; i < friends.size(); i++) {
		dirXNew += friends[i].dirX;
		dirYNew += friends[i].dirY;

		posNewX += friends[i].x;
		posNewY += friends[i].y;

	}
	for (int i = 0; i < toClose.size(); i++) {
		awayFromX += (current.x - toClose[i].x);
		awayFromY += (current.y - toClose[i].y);
	}
	if (friends.size() == 0) {
		return;
	}
	current.dirX += (dirXNew / (float)friends.size()) * 0.1;
	current.dirY += (dirYNew / (float)friends.size()) *0.1;
	current.dirX += (posNewX / (float)friends.size()) * 0.05;
	current.dirY += (posNewY / (float)friends.size()) * 0.05;
	current.dirX += (awayFromX / (float)friends.size()) * 5;
	current.dirY += (awayFromY / (float)friends.size()) * 5;
	float vecLen = sqrt(pow(current.dirX, 2) + pow(current.dirY, 2));
	current.dirX = current.dirX / vecLen;
	current.dirY = current.dirY / vecLen;
	/*if (toClose.size() != 0) {
		current.x += current.dirX * 0.005;
		current.y += current.dirY * 0.005;
	}*/
	arrayOfFishes[x * len + y] = current;
}