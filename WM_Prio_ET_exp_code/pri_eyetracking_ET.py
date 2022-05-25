#===============================================================================
# IMPORTS #
#===============================================================================

# Importing all of the different modules from libraries 
import sys
from psychopy import core, visual, gui, data, misc, event, monitors, sound, clock
from psychopy.tools.monitorunittools import pix2deg
import os
import numpy as np
from CIEcolorwheel import CIEwheel, rotate, cart2pol
import math
import json
import tobii_research as tr
import time
import random
import csv

# Shapes
import shapes_fig

# DIRECTORY #

# Provide a directory where the shape images and instructions images are

directory = "."

#===============================================================================
# DIRECTORY #
#===============================================================================

#found_eyetrackers = tr.find_all_eyetrackers()

os.chdir(directory) # changes current wd to given path

if not os.path.exists('results'): # if there isn't a results folder in the directory then make one
    os.makedirs('results')

#my_eyetracker = found_eyetrackers[0]
#print("Address: " + my_eyetracker.address)
#print("Model: " + my_eyetracker.model)
#print("Name (It's OK if this is empty): " + my_eyetracker.device_name)
#print("Serial number: " + my_eyetracker.serial_number)

#==============================================================================
# PARAMETERS #
#==============================================================================

exp_name = "pri_eyetracking_sim_ss4" # name for the experiment for data file and ppt_id

# TRIAL NUMBERS #

n_trial = 44 * 5 # Default N test trials (was 44 * 5)
n_prac_trial_pri = 5

# TIMINGS

iti = 1 # inter-trial interval
pause = 0.5 # a paused used e.g. before a fixation
presentation = 2 # presentation time
retention = 1 # retention interval

# COLOR SETUP
colorFeedbackRadius = 0.05
Lab = [70, 20, 38]                # L, a, and b values for CIE-Lab color wheel
Labradius = 60                    # radius of color wheel in CIE-Lab color space

#===============================================================================
# DIALOGUE BOX FOR PARTICIPANT INFO #
#===============================================================================

# Creating a dialogue box from the dictionary exp_info

myDlg = gui.Dlg(title="Experiment")
myDlg.addField('Participant number:', 0)
myDlg.addField('Birth date:', 0)
myDlg.addField('Birth month:', 0)
myDlg.addField('Birth year:', 1900)
myDlg.addField('Gender:', choices=["M", "F", "PNS"])
myDlg.addField('Date:', data.getDateStr())

ok_data = myDlg.show()  # show dialog and wait for OK or Cancel
if myDlg.OK:  # or if ok_data is not None
    exp_info = {
        'Participant_number': ok_data[0],
        'birth_day':ok_data[1],
        'birth_month':ok_data[2],
        'birth_year':ok_data[3],
        'gender':ok_data[4],
        'date':ok_data[5]
    }
else:
    print('user cancelled')
    sys.exit(0)
    
ppt_no = exp_info['Participant_number'] # getting the participant number to be used later
ppt_id = exp_name + "_" + str(ppt_no) # Combining the experiment name and ppt_no

gender = exp_info["gender"]

# Getting date of birth by combining elements from the dictionary
dob = str(exp_info['birth_day']) + "/" + str(exp_info['birth_month']) + "/" + str(exp_info['birth_year'])

date = exp_info['date'] # date to be used later

np.random.seed(seed=ppt_no)

# DATA FILE #

# The fle name for saving the data.
file_name = ppt_id + "_" + "_" + exp_info['date']

# Opening the data file in a location. 'w' means it's a file to write to
data_file = open(directory+'/results/'+file_name+'.csv', 'w')

data_headers = [
    'id',
    'gender',
    'dob',
    'date',
    'n_trial',
    'test_stage',
    'condition',
    'tested_position',
    'shape_0',
    'shape_1',
    'shape_2',
    'shape_3',
    'color_0',
    'color_1',
    'color_2',
    'color_3',
    'color_angle_0',
    'color_angle_1',
    'color_angle_2',
    'color_angle_3',
    'correct_response', 
    'correct_response_angle',
    'response', 
    'response_angle',
    'wheel_rotation',
    'reaction_time',
]

# Writing the column headers to file
header_row = ','.join(data_headers) + '\n'
data_file.write(header_row)

# MONITOR
# Technically you don't need to specify all this stuff if your monitor in the monitor centre is
# set up right. However, it's safe to double check

mon_name = "testMonitor" # name in the monitor centre
mon_width = 60 # in cm
mon_dist = 50 # participant distance from monitor in cm
mon_res = [1920, 1080] # monitor resolution

# names of colours to be used as per the file names
stim_size = 1.5 # size in visual angle
n_item = 4


# Creating the window
mywin = visual.Window(size=mon_res, monitor = "testMonitor", fullscr=False, allowGUI=False, color="grey", units = 'deg')

# Default text that will be updated later
text_h = 1
win_text = visual.TextStim(mywin, color="white", height=text_h, pos=[0,0], wrapWidth=25)

mouse = event.Mouse()

# STIMULI
shapes_config = {
    'size': stim_size,
}

# names of shapes to be used
shapes = ['circle', 'square', 'triangle', 'cross']

shape_stims = {
    'circle': shapes_fig.circle(mywin, **shapes_config),
    'square': shapes_fig.square(mywin, **shapes_config),
    'triangle': shapes_fig.triangle(mywin, **shapes_config),
    'cross': shapes_fig.cross(mywin, **shapes_config),
}

color_stims = {
    'circle': shapes_fig.circle(mywin, **shapes_config),
    'square': shapes_fig.square(mywin, **shapes_config),
    'triangle': shapes_fig.triangle(mywin, **shapes_config),
    'cross': shapes_fig.cross(mywin, **shapes_config),
}

# Positions
d = 3.5 # distance from centre of corners on invisible square stims are presented at

# different positions to be used for presenting stimuli.
pos1 = (-d,d)
pos2 = (d, d)
pos3 = (-d,-d)
pos4 = (d, -d)

centre = (0,0)

# Dictionary for the positions.
pos_dict = {0:pos1, 1:pos2, 2:pos3, 3:pos4}
    
#conditions
Prioritise1 = [visual.ImageStim(mywin, image = 'Pri4.png', pos = pos1, size = 2.5, units="deg"), 
              visual.ImageStim(mywin, image = 'Pri1.png', pos = pos2, size = 2.5, units="deg"),
              visual.ImageStim(mywin, image = 'Pri1.png', pos = pos3, size = 2.5, units="deg"),
              visual.ImageStim(mywin, image = 'Pri1.png', pos = pos4, size = 2.5, units="deg")]
              

Prioritise2 = [visual.ImageStim(mywin, image = 'Pri1.png', pos = pos1, size = 2.5, units="deg"), 
              visual.ImageStim(mywin, image = 'Pri4.png', pos = pos2, size = 2.5, units="deg"),
              visual.ImageStim(mywin, image = 'Pri1.png', pos = pos3, size = 2.5, units="deg"),
              visual.ImageStim(mywin, image = 'Pri1.png', pos = pos4, size = 2.5, units="deg")]
              
Prioritise3 = [visual.ImageStim(mywin, image = 'Pri1.png', pos = pos1, size = 2.5, units="deg"), 
              visual.ImageStim(mywin, image = 'Pri1.png', pos = pos2, size = 2.5, units="deg"),
              visual.ImageStim(mywin, image = 'Pri4.png', pos = pos3, size = 2.5, units="deg"),
              visual.ImageStim(mywin, image = 'Pri1.png', pos = pos4, size = 2.5, units="deg")]
              
Prioritise4 = [visual.ImageStim(mywin, image = 'Pri1.png', pos = pos1, size = 2.5, units="deg"), 
              visual.ImageStim(mywin, image = 'Pri1.png', pos = pos2, size = 2.5, units="deg"),
              visual.ImageStim(mywin, image = 'Pri1.png', pos = pos3, size = 2.5, units="deg"),
              visual.ImageStim(mywin, image = 'Pri4.png', pos = pos4, size = 2.5, units="deg")] 
              
NoPrioritise = [visual.ImageStim(mywin, image = 'Pri1.png', pos = pos1, size = 2.5, units="deg"), 
              visual.ImageStim(mywin, image = 'Pri1.png', pos = pos2, size = 2.5, units="deg"),
              visual.ImageStim(mywin, image = 'Pri1.png', pos = pos3, size = 2.5, units="deg"),
              visual.ImageStim(mywin, image = 'Pri1.png', pos = pos4, size = 2.5, units="deg")] 

condition_lookup = {
    'Prioritise1': Prioritise1,
    'Prioritise2': Prioritise2,
    'Prioritise3': Prioritise3,
    'Prioritise4': Prioritise4,
    'NoPrioritise': NoPrioritise}

#====================================
# Main instructions
#====================================

# Creating objects for the instructions images. This could be done more efficiently
# with the dictionary looping approach used above.
# Instructions images, created outside Python using PowerPoint > PDF > PNG

instr_size = [34, 22]

# instructions 
instr1 = visual.ImageStim(mywin, image = 'instr1.png', pos = (0,0), size = instr_size)
instr2 = visual.ImageStim(mywin, image = 'instr2.png', pos = (0,0), size = instr_size)
instr3 = visual.ImageStim(mywin, image = 'instr3.png', pos = (0,0), size = instr_size)
instr4 = visual.ImageStim(mywin, image = 'instr4.png', pos = (0,0), size = instr_size)
instr5 = visual.ImageStim(mywin, image = 'instr5.png', pos = (0,0), size = instr_size)
instr6 = visual.ImageStim(mywin, image = 'instr6.png', pos = (0,0), size = instr_size)
instr7 = visual.ImageStim(mywin, image = 'instr7.png', pos = (0,0), size = instr_size)
instr8 = visual.ImageStim(mywin, image = 'instr8.png', pos = (0,0), size = instr_size)
instr9 = visual.ImageStim(mywin, image = 'instr9.png', pos = (0,0), size = instr_size)
instr10 = visual.ImageStim(mywin, image = 'instr10.png', pos = (0,0), size = instr_size)


# List of instructions
task_instructions_pri = ['instr1','instr2','instr3', 'instr4', 'instr5', 'instr6', 'instr7', 'instr8']

# Dictionary linking the names for each instruction to the image object
instr_dict = {'instr1':instr1,'instr2':instr2,'instr3':instr3, 'instr4':instr4, 'instr5':instr5, 'instr6':instr6, 'instr7':instr7, 'instr8':instr8}

# On screen boxes to press to advance forward and backward through the instructions
next_box = visual.Rect(mywin, width = 2, height=1, pos=[12, 9], fillColor="green") # box for self pacing instructions
next_text = visual.TextStim(mywin, pos=[12,9],text=u"Next",color=u"black", colorSpace='rgb', font=u'Arial', height = 0.5)

back_box = visual.Rect(mywin, width = 2, height=1, pos=[-12,9], fillColor="green") # box for self pacing instructions
back_text = visual.TextStim(mywin, pos=[-12, 9],text=u"Back",color=u"black", colorSpace='rgb', font=u'Arial', height = 0.5)

#===

def instr_loop(instr_list):
    '''Takes a list of instructions names and loops through that list
    presenting them. The instructions in the list given to the function
    must be in the instruction dictionary'''
    j = 0
    while j < len(instr_list):
        escape()
        mouse.setVisible(1)
        instr = instr_dict[instr_list[j]]
        instr.draw()
        next_box.draw()
        next_text.draw()
        back_box.draw()
        back_text.draw()
        mywin.flip()
        
        if mouse.isPressedIn(next_box):
            #SetCursorPos((500,500))
            j = j+1
            event.clearEvents()
            core.wait(0.3)
        elif mouse.isPressedIn(back_box):
            #SetCursorPos((500,500))
            j = j-1
            event.clearEvents()
            core.wait(0.3)
            
#break

break_trials = range(0, 299, 50)[1:]

break_text = u"Please take a break. \nPress SPACE to continue."

def have_break():
    instr(break_text)
   
remind_trials = range(0, 299, 25)[1:]

remind_text = u"\nRemember, if one of the shapes is worth 4 points, try extra hard to remember the colour of that shape. \nIf all of the shapes are worth 1 point, try equally hard to remember the colour of all the shapes. Press SPACE to continue."

def reminder():
    instr(remind_text)

ready_prac = u"Press SPACE when you are ready for the practice."

prac_done_part = "These practice trials are now over. Please inform the experimenter."

prac_done_final = u"Practice done! \nPress SPACE to do it for real. \nRemember, if one of the shapes is worth 4 points, try extra hard to remember the colour of that shape. \nIf all of the shapes are worth 1 point, try equally hard to remember the colour of all the shapes."

finished = u"The session is now over. \nPlease inform the experimenter."

def check_angle_difference(angle1, angle2):
    return 180 - abs(abs(angle1 - angle2) - 180)
    
def random_colors(num):
    random_angles = [] 
    unallowable_range = 20
    for i in range(num):
        while True:
            temp_angle = np.random.randint(0,360, size = 1)
            if isinstance(temp_angle, np.ndarray):
                temp_angle = temp_angle[0]
            too_close = False
            for j in range(len(random_angles)):
                angle_difference = check_angle_difference(temp_angle, random_angles[j])
                if angle_difference < unallowable_range:
                    too_close = True
                    break
            if not too_close:
                random_angles.append(temp_angle)
                break
    return np.array(random_angles)
    
    # [CIEwheel(list[item], Lab, Labradius) for item in range(num)]

def test_color(shape, rotation):
    
    global TS, t_phase
    
    CWradius = np.array([0.25, 0.33])  #inner and outer radius of color wheel in 'height' (in pixels used to be 350, 450)
    CWthickness = CWradius*np.pi/180

    monitor_half_height_degrees = pix2deg(mywin.size[1], mywin.monitor)

    mouse.setPos(newPos=(0,0))
    mouse.setVisible(True)
    slices = []
    orientation = list(range(0,360)) # initialize
    orient2angle = list(range(0,360)) # initialize - vector converting orientations back to (polar) angles (in degrees)
    for angle in range(0,360): 
        orientation[angle] = rotate(360-angle, -90) #ori goes clockwise from 12, angle goes counterclockwise from 3 o'clock, so convert angle to ori by mirroring (along vertical axis), then rotate counter-clockwise (i.e., add rot to angle) so that angle=0 is at ori=90
        orient2angle[orientation[angle]] = angle    
        slicecolor = CIEwheel(angle, Lab, Labradius)
        slices.append(visual.ShapeStim(win=mywin, closeShape=True, vertices=((0,CWradius[0]),(0,CWradius[1]),
                        (CWthickness[1],CWradius[1]),(CWthickness[0],CWradius[0])), 
                        units='height', fillColorSpace="rgb", fillColor=slicecolor, lineWidth=0, pos=[0,0], ori=orientation[angle])) 
    CWcircle = visual.Circle(win=mywin, radius=CWradius[1], units='height', pos=[0,0])

    for x in range(0,360):
        slices[x].ori = rotate(slices[x].ori, rotation)
        slices[x].setAutoDraw(True)
    
    color_stim = color_stims[shape]
    color_stim.fillColor = [-0.6, -0.6, -0.6]
    color_stim.lineColor = [-0.6, -0.6, -0.6]
    color_stim.setAutoDraw(True)
    clicked = False 
    response = None
    
    start_time = clock.getTime() 
    t_phase = 9   
    TS = start_time 
    
    while clicked == False:
        mouseXY = mouse.getPos()
        polar = cart2pol(mouseXY[0], mouseXY[1])
        if (polar[0] >= CWradius[0] * monitor_half_height_degrees and polar[0] <= CWradius[1] * monitor_half_height_degrees): # check if within colour wheel
            selectedOrientation = orientation[int(polar[1])] #computes orientation of mouse position
            rotatedOrientation = rotate(selectedOrientation, -rotation) #rotates it back (in orientation space)
            backrotatedAngle = orient2angle[rotatedOrientation]         #converts it into (color) angle
            pointedcolor = CIEwheel(backrotatedAngle, Lab, Labradius)
            color_stim.setFillColor(pointedcolor, colorSpace='rgb')  #sets the selected color to the current mouse angle
            color_stim.setLineColor(pointedcolor, colorSpace='rgb')
        else:
            color_stim.fillColor = [-0.6, -0.6, -0.6]
            color_stim.lineColor = [-0.6, -0.6, -0.6]

        for x in range(0, 360):
            if mouse.isPressedIn(slices[x]):
                response_color = CIEwheel(x, Lab, Labradius)
                response_color_angle = x
                clicked = True
        mywin.flip()
    
    t_phase = 10
    TS = clock.getTime()
    
    # Clean up!
    color_stim.setAutoDraw(False)
    for x in range(0,360):
        slices[x].setAutoDraw(False)
    
    escape()

    mouse.setVisible(False)
    
    return {
        'color': response_color,
        'color_angle':response_color_angle,
        'wheel_rotation': rotation,
        'reaction_time': clock.getTime() - start_time,
    }
    
def instr(text, wait_space = True, wait = None):
    '''Present some instruction text and then allow participants to press space to advance if wait_space is true.
    Otherwise present the text and advance after wait seconds. (Adapted from code by Jason Doherty, University of Edinburgh)'''
    
    global TS, t_phase
    
    event.clearEvents()
    mywin.flip()

    win_text.setText(text)
    win_text.draw()
    mywin.flip() # text on
    TS = clock.getTime()

# if wait_space is True
    if wait_space:
        resp = 0
        while resp == 0:
            win_text.draw()
            mywin.flip()
            for key in event.getKeys():
                if key in ['space']:
                    resp += 1
                elif key == 'escape': # allow to escape
                    core.quit()
    else:
        core.wait(wait)
    mywin.flip() # stop presenting instructions

#===
        
def present_trial(trial, test_stage):
    
    global TS, t_phase
        
    mouse.setVisible(False)
    mywin.flip()
    t_phase = 1
    TS = clock.getTime()
    core.wait(iti) # blank for iti (1000ms)
    
    win_text.setText("la")
    win_text.draw()
    mywin.flip() # la on
    t_phase = 2
    TS = clock.getTime()
    core.wait(iti)
    
    win_text.setText("+")
    win_text.draw()
    mywin.flip() # la on
    t_phase = 3
    TS = clock.getTime()
    core.wait(pause)
    
    mywin.flip()
    t_phase = 4
    TS = clock.getTime() # THIS REPLACES MYWIN.FLIP() WHICH WAS PREVIOUSLY AFTER CORE.WAIT(ITI). 
    # YOU ADDED A TS TO THE MYWIN.FLIP(), WAS THIS MEANT TO GRAB THE TIME WHEN ITI STARTS?
    core.wait(iti) # blank for iti (1000ms)
    

    condition_stims = condition_lookup[trial['condition']]
    for drawim in condition_stims:
        drawim.draw()
    
    mywin.flip() # numbers ON
    t_phase = 5
    TS = clock.getTime()
    core.wait(iti) # pri numbers for iti (1000ms)
    
    mywin.flip() # numbers OFF\
    t_phase = 6
    TS = clock.getTime()
    core.wait(pause) # blank for pause (500ms)
    
    for i in range(n_item):
        shape = trial['shapes'][i]
        position = trial['positions'][i]
        color = trial['colors'][i]
        
        stim = shape_stims[shape]
        
        stim.pos = pos_dict[position]
        rgb_color = CIEwheel(color, Lab, Labradius)
        stim.fillColor = rgb_color
        stim.lineColor = rgb_color
        stim.draw()
        
    mywin.flip() # shapes ON
    t_phase = 7
    TS = clock.getTime()
    core.wait(presentation) # show shapes for presentation (2000ms)
    
    mywin.flip() # shapes OFF
    t_phase = 8
    TS = clock.getTime()
    core.wait(retention) # blank for retention (1000ms)
    
    response = test_color(trial['shapes'][trial['tested_position']], trial['rotation'])
    
    save_data(trial, test_stage, response) # end of trial?
    
    i = trial['n_trial']
    
    if i in break_trials:
        have_break()
        
    if i in remind_trials:
        reminder()
        
    # test screen displayed until participant responds
    
def format_color(color):
    return '"' + (','.join([str(c) for c in color])) + '"'
    
def save_data(trial, test_stage, response):
    row = {
        'id': ppt_id,
        'gender': gender,
        'dob': dob,
        'date': date,
        'n_trial': trial['n_trial'],
        'test_stage': test_stage,
        'condition': trial['condition'],
        'tested_position': trial['tested_position'],
        'correct_response': format_color(CIEwheel(trial['colors'][trial['tested_position']], Lab, Labradius)), 
        'correct_response_angle': trial['colors'][trial['tested_position']],
        'response': format_color(response['color']),
        'response_angle': response['color_angle'],
        'reaction_time': response['reaction_time'],
        'wheel_rotation': response['wheel_rotation'],
    }
    
    for s in range(len(trial['shapes'])):
        row['shape_' + str(s)] = trial['shapes'][s]
    
    for c in range(len(trial['colors'])):
        row['color_' + str(c)] = format_color(CIEwheel(trial['colors'][c], Lab, Labradius))
        row['color_angle_' + str(c)] = trial['colors'][c]
    
    values = []
    for h in data_headers:
        if h in row:
            values.append(row[h])
        else:
            values.append('')
    
    data_file.write(','.join([str(v) for v in values]) + '\n')
    data_file.flush()
    
def get_probes(n, n_item):
    probes = list(range(n_item)) * int(n / n_item)
    np.random.shuffle(probes)
    return(probes)
    
def get_trials(n_trial):
    trials = []
    items = list(range(n_item))
    
    conditions = ['Prioritise1', 'Prioritise2', 'Prioritise3', 'Prioritise4', 'NoPrioritise']
    n_per_condition = int(n_trial / len(conditions))
    
    for c in conditions:
        probes = get_probes(n_per_condition, n_item)
        probes.sort()
         
        for trial_in_condition in range(len(probes)):
            probe = probes[trial_in_condition]
            
            trial_shapes = list(shapes)
            np.random.shuffle(trial_shapes)
            
            trial = {
                'condition': c,
                'shapes': trial_shapes,
                'positions': [0, 1, 2, 3],
                'tested_position': probe,
                'colors': random_colors(n_item),
                'rotation': np.random.randint(0,360)
            }
            
            trials.append(trial)
            
    np.random.shuffle(trials)
    
    for i in range(len(trials)):
        trials[i]['n_trial'] = i + 1
    
    return trials
    
def shuffle_shapes():
    trial_shapes = list(shapes)
    np.random.shuffle(trial_shapes)
    return trial_shapes
    
def get_prac_trials_pri(n_prac_trial_pri):
    prac_trial_pri = [
    {
    #equal 
    'condition': 'NoPrioritise',
    'shapes': shuffle_shapes(),
    'positions': [0, 1, 2, 3],
    'tested_position': 1,
    'colors': random_colors(n_item),
    'rotation': np.random.randint(0,360)
    },
    #Pri1 
    {
    'condition': 'Prioritise1',
    'shapes': shuffle_shapes(),
    'positions': [0, 1, 2, 3],
    'tested_position': 0,
    'colors': random_colors(n_item),
    'rotation': np.random.randint(0,360)
    },
    {
    #Pri2
    'condition': 'Prioritise2',
    'shapes': shuffle_shapes(),
    'positions': [0, 1, 2, 3],
    'tested_position': 3,
    'colors': random_colors(n_item),
    'rotation': np.random.randint(0,360)
    },
    {
    #Pri3
    'condition': 'Prioritise3',
    'shapes': shuffle_shapes(),
    'positions': [0, 1, 2, 3],
    'tested_position': 3,
    'colors': random_colors(n_item),
    'rotation': np.random.randint(0,360)
    },
    #Pri4
    {
    'condition': 'Prioritise4',
    'shapes': shuffle_shapes(),
    'positions': [0, 1, 2, 3],
    'tested_position': 1,
    'colors': random_colors(n_item),
    'rotation': np.random.randint(0,360)
    }
    ]
    
    np.random.shuffle(prac_trial_pri)
    
    for i in range(len(prac_trial_pri)):
        prac_trial_pri[i]['n_trial'] = i + 1
    
    return prac_trial_pri
        
        
def present_trials(trials, test_stage):
    global trialNum
    for trial in trials:
        trialNum = trial['n_trial']
        present_trial(trial, test_stage)
    

def write_trial_structure(trials):
    file_name_potential = ppt_id + "_" + exp_info['date']
    file = open(directory+'/potential_results/'+ file_name_potential + '_potential_trials.csv', 'w')
    
    columns = ['n_trial', 'condition', 'tested_position', 'shape_0', 'shape_1', 'shape_2', 'shape_3', 'color_0', 'color_1', 'color_2', 'color_3', 'color_angle_0', 'color_angle_1', 'color_angle_2', 'color_angle_3', 'correct_response', 'correct_response_angle', 'wheel_rotation']
    headers = ','.join(columns) + '\n'
    file.write(headers)
    
    for trial in trials:
        row = {
            'n_trial': trial['n_trial'],
            'condition': trial['condition'],
            'tested_position': trial['tested_position'],
            'correct_response': format_color(CIEwheel(trial['colors'][trial['tested_position']], Lab, Labradius)), 
            'correct_response_angle': trial['colors'][trial['tested_position']],
            'wheel_rotation': trial['rotation']
        }
        
        for s in range(len(trial['shapes'])):
            row['shape_' + str(s)] = trial['shapes'][s]
        
        for c in range(len(trial['colors'])):
            row['color_' + str(c)] = format_color(CIEwheel(trial['colors'][c], Lab, Labradius))
            row['color_angle_' + str(c)] = trial['colors'][c]
        
        values = []
        for h in columns:
            if h in row:
                values.append(row[h])
            else:
                values.append('')
        
        file.write(','.join([str(v) for v in values]) + '\n')
        
    file.flush()
    file.close()

# Generate all trials

trials = get_trials(n_trial)
prac_trial_pri = get_prac_trials_pri(n_prac_trial_pri)

write_trial_structure(trials)

def escape():
    ''' Exits the task when escape is pressed'''
    while True:
        for key in event.getKeys():
           if key in['escape']:
                core.quit()
        break

# eye tracking variables
runET = True # run with the eye-tracker or not?
writeHeader = True # used to set a header row once

TS = 0 # variable for PP timestamps 
t_phase = 0 # variable for trial phase information

ET_filename = "ET_Data/ET_csv_" + str(ppt_no) + ".csv"

# eyetracker function for collecting and writing data to csv
if runET == True:
    # connect to eye=tracker
    found_eyetrackers = tr.find_all_eyetrackers()

    my_eyetracker = found_eyetrackers[0]
    print("Address: " + my_eyetracker.address)
    print("Model: " + my_eyetracker.model)
    print("Name (It's OK if this is empty): " + my_eyetracker.device_name)
    print("Serial number: " + my_eyetracker.serial_number)

    def gaze_data_callback(gaze_data):
        with open(ET_filename, 'a', newline = '') as f:  # You will need 'wb' mode in Python 2.x
            
            global writeHeader, trialNum, t_phase, TS
            
            gaze_data["trial"] = trialNum
            gaze_data["trial_phase"] = t_phase
            gaze_data["pp_TS"] = TS
            
            w = csv.DictWriter(f, gaze_data.keys())
            if writeHeader == True:
                w.writeheader()
                writeHeader = False
            w.writerow(gaze_data)
            f.close()



# Practice trials

instr_loop(task_instructions_pri)
instr(ready_prac)
present_trials(prac_trial_pri, "practice_pri")
instr(prac_done_part)

# Main trials
if runET == True: 
    my_eyetracker.subscribe_to(tr.EYETRACKER_GAZE_DATA, gaze_data_callback, as_dictionary=True)
    
present_trials(trials, "test")

# turn eye-tracker off
if runET == 1: 
    my_eyetracker.unsubscribe_from(tr.EYETRACKER_GAZE_DATA, gaze_data_callback)
    
win.close()