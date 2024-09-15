#!/usr/bin/env python
from IdToName import *
from IdFromString import *
import numpy as np


def GetIds(ids_names):
    """GETIDS - Output ids from a given array of IDs and test names

    The test names can be any string or substring present in the test's name 
    (first line of corresponding file). Test names are case sensitive.

    Usage:
        ids = GetIds(101)
        ids = GetIds('Dakota')
        ids = GetIds([101, 102...])
        ids = GetIds([\'Dakota\', \'Slc\'...])
        ids = GetIds([[101, 102...], [\'Dakota\', \'Slc\'...]])
    """

    ids = []

    # Non-list input: either an ID or a test name
    if type(ids_names) == str:
        ids = IdFromString(ids_names)
        if len(ids) == 0:
            # fail silently
            return []
        #raise RuntimeError('runme.py: GetIds.py: No tests with names matching "' + ids_names + '" were found. Note that name checking is case sensitive. Test names are in the first line of a given test eg: "Square" would include test101.py: "SquareShelfConstrainedStressSSA2d"')

    # Non-list input: ID
    if type(ids_names) == int:
        ids = [ids_names]
        if len(ids) == 0:
            # fail silently
            return []
        #raise RuntimeError('runme.py: GetIds.py: No tests with ids matching "' + ids_names + '" were found. Check that there is a test file named "test' + str(ids_names) + '.py"')

    # many inputs of either ids or test names
    if type(ids_names) == list and len(ids_names) > 0:
        # is everything a string or int?
        if np.array([type(i) == int for i in ids_names]).all():
            ids = ids_names
        elif np.array([type(i) == np.int64 for i in ids_names]).all():
            ids = ids_names
        elif np.array([type(i) == str for i in ids_names]).all():
            ids = np.concatenate([IdFromString(i) for i in ids_names])
            if len(ids) == 0:
                raise RuntimeError('runme.py: GetIds.py: No tests with names matching "' + ids_names + '" were found. Note that name checking is case sensitive.')

    # many inputs of both ids and test names
    # ids_names[0] -> ids_names by id
    # ids_names[1] -> ids_names by test name
    #
    # NOTE: ID inclusion/exclusion lists will always hit this condition 
    #       becasue of the way their respective arguments are gathered at the 
    #       end of __main__ in the call to function runme.
    if type(ids_names) == list and len(ids_names) == 2:
        if type(ids_names[0]) == list and len(ids_names[0]) > 0:
            ids_expanded = []
            for i in ids_names[0]:
                # Handle case where list element follows MATLAB range syntax
                if ':' in i:
                    i_range = i.split(':')
                    for j in range(int(i_range[0]), int(i_range[1])):
                        ids_expanded.append(j)
                else:
                    ids_expanded.append(int(i))
            unique_ids = list(set(ids_expanded))
            ids += unique_ids
        if type(ids_names[1]) == list and len(ids_names[1]) > 0 and type(ids_names[1][0]) == str:
            ids = np.concatenate([ids, np.concatenate([IdFromString(i) for i in ids_names[1]])])
            if len(ids) == 0:
                raise RuntimeError('runme.py: GetIds.py: No tests with names matching "' + ids_names + '" were found. Note that name checking is case sensitive.')

    # no recognizable ids or id formats
    if np.size(ids) == 0 and not np.all(np.equal(ids_names, None)):
        raise RuntimeError('runme.py: GetIds.py: include and exclude options (-i/--id; -in/--include_name; -e/--exclude; -en/--exclude_name) options must follow GetIds usage format:\n' + GetIds.__doc__)

    return np.array(ids).astype(int)
