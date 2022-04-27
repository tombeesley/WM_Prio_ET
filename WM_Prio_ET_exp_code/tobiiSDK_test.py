from psychopy import visual, core, gui, event
import numpy as np
import csv
import os.path
import random
import tobii_research as tr
import time

f = open('csvfile.csv','w')
f.write('new file\n')
f.close()

runET = 1
writeHeader = True

TS = 0 # variable for PP timestamps 
t_phase = 0 # variable for trial phase information

if runET == 1:
    # connect to eye=tracker
    found_eyetrackers = tr.find_all_eyetrackers()

    my_eyetracker = found_eyetrackers[0]
    print("Address: " + my_eyetracker.address)
    print("Model: " + my_eyetracker.model)
    print("Name (It's OK if this is empty): " + my_eyetracker.device_name)
    print("Serial number: " + my_eyetracker.serial_number)
    print("NEW")  

    def gaze_data_callback(gaze_data):
        # Print gaze points of left and right eye
#        print("Left eye: ({gaze_left_eye}) \t Right eye: ({gaze_right_eye})".format(
#            gaze_left_eye=gaze_data['left_gaze_point_on_display_area'],
#            gaze_right_eye=gaze_data['right_gaze_point_on_display_area']))
        with open('csvfile.csv', 'a', newline = '') as f:  # You will need 'wb' mode in Python 2.x
            
            global writeHeader, trial, t_phase, TS
            
            gaze_data["trial"] = trial
            gaze_data["trial_phase"] = t_phase
            gaze_data["pp_TS"] = TS
            
            w = csv.DictWriter(f, gaze_data.keys())
            if writeHeader == True:
                w.writeheader()
                writeHeader = False
            w.writerow(gaze_data)

winWidth = 1440; winHeight = 810
win = visual.Window(
    size=[winWidth, winHeight],
    units="pix",
    fullscr=False,
    color=[0.5,0.5,0.5])

L_cue = visual.Circle(\
win=win, pos=[-400,0], radius = 100, edges = 128, fillColorSpace = 'rgb255', fillColor = [0,0,0], lineWidth = 0)

R_cue = visual.Circle(\
win=win, pos=[400,0], radius = 100, edges = 128, fillColorSpace = 'rgb255', fillColor = [0,0,0], lineWidth = 0)

# turn eye-tracker on
if runET == 1: 
    my_eyetracker.subscribe_to(tr.EYETRACKER_GAZE_DATA, gaze_data_callback, as_dictionary=True)

for trial in range(1,5):

    L_cue.draw()
    R_cue.draw()

    # stimulus on
    TS = win.flip()
    t_phase = 1 # start of the "stimulus on" phase
    core.wait(2)

    # stimulus off
    TS = win.flip()
    t_phase = 2 # start of the "stimulus off" phase
    core.wait(1)

# turn eye-tracker off
if runET == 1: 
    my_eyetracker.unsubscribe_from(tr.EYETRACKER_GAZE_DATA, gaze_data_callback)



win.close()