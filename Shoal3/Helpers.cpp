#include "Helpers.h"

float getAngle(float x1, float y1, float x2, float y2) {
	float value = x1 * x2 + y1 *y2;
	value = value != 0 ? value / sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2)) : 0;
	return 180 - atan2(-y1, x1) * 57.0;
}
float vectorMultiply(float x1, float y1, float x2, float y2) {
	float value = x1 * x2 + y1 *y2;
	value = value != 0 ? value / sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2)) : 0;
	return value;
}
float getVectorLength(float x1, float y1, float x2, float y2) {
	return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
}