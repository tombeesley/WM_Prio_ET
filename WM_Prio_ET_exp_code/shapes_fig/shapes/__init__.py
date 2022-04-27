import psychopy

def circle(win, **kwargs):
    circle_stim = psychopy.visual.Circle(win,
        units="deg",
        fillColor=[1, -1, -1],
        lineColor=[1, -1, -1],
        **kwargs,
    )

    return circle_stim

def square(win, **kwargs):
    square_stim = psychopy.visual.Rect(win,
        units="deg",
        fillColor=[1, -1, -1],
        lineColor=[1, -1, -1],
        width=1,
        height=1,
        **kwargs,
    )

    return square_stim

def triangle(win, **kwargs):
    triangle_stim = psychopy.visual.ShapeStim(win,
        vertices=[
            (0, 0.5),
            (0.5, -0.5),
            (-0.5,-0.5),
        ],
        units="deg",
        fillColor=[1, -1, -1],
        lineColor=[1, -1, -1],
        **kwargs,
    )

    return triangle_stim

def cross(win, **kwargs):
    cross_stim = psychopy.visual.ShapeStim(win,
        vertices=[
            (-0.25, -0.5),
            (0.25, -0.5),
            (0.25, -0.25),
            (0.5, -0.25),
            (0.5, 0.25),
            (0.25, 0.25),
            (0.25, 0.5),
            (-0.25, 0.5),
            (-0.25, 0.25),
            (-0.5, 0.25),
            (-0.5, -0.25),
            (-0.25, -0.25),
        ],
        units="deg",
        fillColor=[1, -1, -1],
        lineColor=[1, -1, -1],
        **kwargs,
    )

    return cross_stim
    
#def cross(win, **kwargs):
    #rect1 = psychopy.visual.Rect(win,
    #units="deg",
    #fillColor=[1, -1, -1],
    #lineColor=[1, -1, -1]
    #**kwargs,
    #)
    
    
    #rect2 = psychopy.visual.Rect(win,
    #units="deg",
    #fillColor=[1, -1, -1],
    #lineColor=[1, -1, -1],
    #**kwargs,
    #)

    #return cross_stim
