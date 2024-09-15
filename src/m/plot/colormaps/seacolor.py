import numpy as np


def seacolor(n=256):
    '''SEACOLOR Sea colormap'''

    J = [0.0392, 0, 0.4745,
         0.1020, 0, 0.5373,
         0.1020, 0, 0.5373,
         0.1490, 0, 0.5961,
         0.1490, 0, 0.5961,
         0.1059, 0.0118, 0.6510,
         0.1059, 0.0118, 0.6510,
         0.0627, 0.0235, 0.7059,
         0.0627, 0.0235, 0.7059,
         0.0196, 0.0353, 0.7569,
         0.0196, 0.0353, 0.7569,
         0, 0.0549, 0.7961,
         0, 0.0549, 0.7961,
         0, 0.0863, 0.8235,
         0, 0.0863, 0.8235,
         0, 0.1176, 0.8471,
         0, 0.1176, 0.8471,
         0, 0.1529, 0.8745,
         0, 0.1529, 0.8745,
         0.0471, 0.2667, 0.9059,
         0.0471, 0.2667, 0.9059,
         0.1020, 0.4000, 0.9412,
         0.1020, 0.4000, 0.9412,
         0.0745, 0.4588, 0.9569,
         0.0745, 0.4588, 0.9569,
         0.0549, 0.5216, 0.9765,
         0.0549, 0.5216, 0.9765,
         0.0824, 0.6196, 0.9882,
         0.0824, 0.6196, 0.9882,
         0.1176, 0.6980, 1.0000,
         0.1176, 0.6980, 1.0000,
         0.1686, 0.7294, 1.0000,
         0.1686, 0.7294, 1.0000,
         0.2157, 0.7569, 1.0000,
         0.2157, 0.7569, 1.0000,
         0.2549, 0.7843, 1.0000,
         0.2549, 0.7843, 1.0000,
         0.3098, 0.8235, 1.0000,
         0.3098, 0.8235, 1.0000,
         0.3686, 0.8745, 1.0000,
         0.3686, 0.8745, 1.0000,
         0.5412, 0.8902, 1.0000,
         0.5412, 0.8902, 1.0000,
         0.7373, 0.9020, 1.0000]

    # J is a series of r, g, b triples, reshape it as such
    length = int(len(J) / 3)
    J = np.array(J).reshape(length, 3)
    a = np.linspace(1, length, n)
    b = np.arange(1, length + 1)

    # interpolate color on each channel r, g, b
    y = np.array([np.interp(a, b, J[:, i]) for i in range(3)])

    return y
