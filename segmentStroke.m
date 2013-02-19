function [ segpoints, segtypes ] = segmentStroke( stroke )
    speedSmoothingWindow = 5;       % points (starts at 2 on each side)
    tangentWindowSize = 11;         % points to regress to find tangent
    firstSpeedThreshold = .25;      % percent of average speed
    curvatureThreshold = .75;       % degrees per pixel
    secondSpeedThreshold = .8;      % percent of average speed
    minimumCornerDistance = 5;      % distance between allowable corners
    minimumArcAngle = 36;           % degrees for loosest arc
    
    numPoints = size(stroke.x);
    numPoints = numPoints(1);
    
    function length = distance(x1, y1, x2, y2)
        length = sqrt( (x2 - x1) ^ 2 + (y2 - y1) ^ 2 );
    end

    function speed = penSpeed(index)
        eachSideWindow = floor(speedSmoothingWindow / 2);
        
        
        if index < 1 + eachSideWindow
            speed = penSpeed(1 + eachSideWindow);
            return
        end
        
        if index > numPoints - eachSideWindow
            speed = penSpeed(numPoints - eachSideWindow);
            return
        end
        
        length = arcLengths(index + eachSideWindow) - arcLengths(index - eachSideWindow);
        time = stroke.t(index + eachSideWindow) - stroke.t(index - eachSideWindow);
        speed = length / time;
    end

    arcLengths = zeros(1, numPoints);
    arcLengths(1) = 0;
    
    for i=2:size(stroke.x)
        arcLengths(i) = arcLengths(i - 1) + ...
            distance(stroke.x(i - 1), stroke.y(i - 1), stroke.x(i), stroke.y(i));
    end
    
    penSpeeds = zeros(1, numPoints);
    for i=1:numPoints
        penSpeeds(i) = penSpeed(i);
    end
    
    penSpeeds
    
    segpoints = 0;
    segtypes = 0;
end



