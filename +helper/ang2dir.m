function dir = ang2dir(theta)
    dir = mod(int8(4 * theta/pi), 8);
end