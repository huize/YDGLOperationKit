//
//  esTransform.h
//  test_openges
//
//  Created by 辉泽许 on 16/1/12.
//  Copyright © 2016年 yifan. All rights reserved.
//

#ifndef esTransform_h
#define esTransform_h


#endif /* esTransform_h */



// The MIT License (MIT)
//
// Copyright (c) 2013 Dan Ginsburg, Budirijanto Purnomo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

//
// Book:      OpenGL(R) ES 3.0 Programming Guide, 2nd Edition
// Authors:   Dan Ginsburg, Budirijanto Purnomo, Dave Shreiner, Aaftab Munshi
// ISBN-10:   0-321-93388-5
// ISBN-13:   978-0-321-93388-1
// Publisher: Addison-Wesley Professional
// URLs:      http://www.opengles-book.com
//            http://my.safaribooksonline.com/book/animation-and-3d/9780133440133
//
// ESUtil.c
//
//    A utility library for OpenGL ES.  This library provides a
//    basic common framework for the example applications in the
//    OpenGL ES 3.0 Programming Guide.
//

///
//  Includes
//

#include <math.h>
#include <string.h>
#include <OpenGLES/ES2/gl.h>

typedef struct
{
    GLfloat   m[4][4];
} ESMatrix;

#define PI 3.1415926535897932384626433832795f

#define ESUTIL_API

void ESUTIL_API
esScale ( ESMatrix *result, GLfloat sx, GLfloat sy, GLfloat sz );

void ESUTIL_API
esTranslate ( ESMatrix *result, GLfloat tx, GLfloat ty, GLfloat tz );

void ESUTIL_API
esRotate ( ESMatrix *result, GLfloat angle, GLfloat x, GLfloat y, GLfloat z );

void ESUTIL_API
esFrustum ( ESMatrix *result, float left, float right, float bottom, float top, float nearZ, float farZ );


void ESUTIL_API
esPerspective ( ESMatrix *result, float fovy, float aspect, float nearZ, float farZ );

void ESUTIL_API
esOrtho ( ESMatrix *result, float left, float right, float bottom, float top, float nearZ, float farZ );


void ESUTIL_API
esMatrixMultiply ( ESMatrix *result, ESMatrix *srcA, ESMatrix *srcB );


void ESUTIL_API
esMatrixLoadIdentity ( ESMatrix *result );

void ESUTIL_API
esMatrixLookAt ( ESMatrix *result,
                float posX,    float posY,    float posZ,
                float lookAtX, float lookAtY, float lookAtZ,
                float upX,     float upY,     float upZ );
