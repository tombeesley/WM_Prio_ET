# -*- coding: utf-8 -*-
"""
Created on Tue Mar 29 17:04:56 2016

@author: Klaus Oberauer
"""
# turns angle (degrees) into into RGB values for a CIE-Lab color wheel with 
# L, a, and b given in Lab, and radius of the Lab wheel given in LabRadius

from __future__ import division  # so that 1/3=0.333 instead of 1/3=0
from numpy import pi, sin, cos, arctan2, min, sqrt

def CIEwheel(angle, Lab, LabRadius):
    theta = angle * pi / 180
    #print(['theta = ', theta])
    L = Lab[0]
    A = Lab[1] + LabRadius*cos(theta)
    B = Lab[2] + LabRadius*sin(theta)
    #print(['ABL = ', A, B, L])
    
    # convert Lab to XYZ
    Y = (L+16)/115
    X = A/500 + Y
    Z = Y - B/200
    #print(['XYZ 1 = ', X,Y,Z])
    
    #filter X, Y, Z with threshold 0.008856
    threshold = 0.008856
    if (X**3 > threshold):
        X = X**3
    else:
        X = (X - 16/116) / 7.787
    if (Y**3 > threshold):
        Y = Y**3
    else:
        Y = (Y - 16/116) / 7.787    
    if (Z**3 > threshold):
        Z = Z**3
    else:
        Z = (Z - 16/116) / 7.787    
    #print(['XYZ 2 = ', X,Y,Z])     
     
     
    # define reference points
    refX = 95.047
    refY = 100
    refZ = 108.883
    
    #rescale X, Y, Z according to reference points
    X = refX * X / 100
    Y = refY * Y / 100
    Z = refZ * Z / 100
   # print(['XYZ 3 = ', X,Y,Z])
    
    # convert to RGB
    R = X * 3.2406 + Y * -1.5372 + Z * -0.4986
    G = X * -0.9689 + Y * 1.8758 + Z * 0.0415
    B = X * 0.0557 + Y * -0.2040 + Z * 1.0570
    
    # gamma correction to IEC 61966-2-1 standard
    threshold2 = 0.0031308
    if (R > threshold2):
        R = 1.055 * R**(1/2.4) - 0.055
    else:
        R = 12.92 * R
    if (G > threshold2):
        G = 1.055 * G**(1/2.4) - 0.055
    else:
        G = 12.92 * G    
    if (B > threshold2):
        B = 1.055 * B**(1/2.4) - 0.055
    else:
        B = 12.92 * B 
        
    # Trim between 0 and 1, concatenate
    RGB = [ max([0,min([1,R])]), max([0,min([1,G])]), max([0, min([1,B])]) ]
    rescaledRGB = [2*(x - 0.5) for x in RGB]  # bring into range from -1 to 1
    return rescaledRGB
    
    

#%%
# function for rotating angle (in degrees), positive rot(ation) -> clockwise, negative rot -> counter-clockwise
def rotate(theta, rot):
    newtheta = theta - rot  # clockwise rotation requires reduction of angle! (angle increases counter-clockwise)
    if (newtheta) >= 360:
        newtheta = newtheta - 360
    if (newtheta) < 0:
        newtheta = newtheta + 360
    return(newtheta)


#%%
# compute signed angular difference (in degrees) for response on color wheel
def angDiff(theta1, theta2):
    d = theta1 - theta2
    if (d < -180):
        d = theta1 - theta2 + 360
    if (d > 180):
        d = theta1 - theta2 - 360
    return(d)

#%%
# define a function to convert Cartesian coordinates into polar (= angles)
def cart2pol(x, y):
    rho = sqrt(x**2 + y**2)
    phi = 180*arctan2(y, x)/pi  #arctan2 gives angle in radians from -pi:pi -> convert to degrees from 0:360
    if (phi < 0): phi = phi+360
    return(rho, phi)