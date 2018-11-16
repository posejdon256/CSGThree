#pragma once
#include "Helpers.h"
struct  fish
{
	int id;
	float dirX;
	float dirY;
	float x;
	float y;
};
void defineFishes();
fish* getArrayOfFishes();
void updateShoal();
void updateInNeighborhoud(int, int);