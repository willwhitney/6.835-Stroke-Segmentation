function [ segpoints, segtypes ] = segmentStroke( stroke )
    speedSmoothingWindow = 6;           % points (starts at 2 on each side)
    tangentWindow = 10;                 % points to regress to find tangent
    firstSpeedThresholdPercent = .25;   % percent of average speed
    curvatureThreshold = .75;           % degrees per pixel
    secondSpeedThresholdPercent = .8;   % percent of average speed
    minimumCornerDistance = 200;          % distance between allowable corners
    minimumArcAngle = 36;               % degrees for loosest arc
    
    minimumStartDistance = 500;
    
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

    function tan = tangent(index)
        eachSideWindow = floor(tangentWindow / 2);
        minimum = max(index - eachSideWindow, 1);
        maximum = min(index + eachSideWindow, numPoints);
        count = maximum - minimum + 1;
        tan = regress(stroke.y(minimum:maximum), [ones(count, 1), (1:count)']);
    end

    function curve = curvature(index)
        eachSideWindow = floor(tangentWindow / 2);
        minimum = max(index - eachSideWindow, 1);
        maximum = min(index + eachSideWindow, numPoints);
        count = maximum - minimum + 1;
        curve = regress(angles(minimum:maximum)', ...
            [ones(count, 1), arcLengths(minimum:maximum)']);
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
    
    plot(penSpeeds)
    
    tangents = zeros(1, numPoints);
    for i=1:numPoints
        tan = tangent(i);
        tangents(i) = tan(2);
    end
    
    angles = radtodeg(atan(tangents));
    
    curvatures = zeros(1, numPoints);
    for i=1:numPoints
        curve = curvature(i);
        curvatures(i) = curve(2);
    end

    avgSpeed = arcLengths(numPoints) / ( stroke.t(numPoints) - stroke.t(1));
    firstSpeedThreshold = avgSpeed * firstSpeedThresholdPercent;
    secondSpeedThreshold = avgSpeed * secondSpeedThresholdPercent;
    
    [speedPeaks, speedPeakLocations] = findpeaks(penSpeeds * -1);
    speedPeaks = -1 * speedPeaks;
    
    speedMatches = [];
    speedPeaksSize = size(speedPeaks);
    for i=1:speedPeaksSize(2)
        if speedPeaks(i) < firstSpeedThreshold
            speedMatches...
                = [speedMatches, speedPeakLocations(i)];
        end
    end
    
    [curvePeaks, curvePeakLocations] = findpeaks(curvatures);
    curvatureMatches = [];
    curvePeaksSize = size(curvePeaks);
    for i=1:curvePeaksSize(2)
        if curvePeaks(i) > curvatureThreshold
            if penSpeeds(curvePeakLocations(i)) < secondSpeedThreshold;
                curvatureMatches...
                    = [curvatureMatches, curvePeakLocations(i)];
            end
        end
    end
    
%     curvatureMatches
%     speedMatches
    
    updatedSpeedMatches = [];
    curvatureMatchesSize = size(curvatureMatches);
    for cIndex=1:curvatureMatchesSize(2)
        updatedSpeedMatches = speedMatches;
        speedMatchesSize = size(speedMatches);
        for sIndex=1:speedMatchesSize(2)
            x1 = stroke.x(curvatureMatches(cIndex));
            y1 = stroke.y(curvatureMatches(cIndex));
            x2 = stroke.x(speedMatches(sIndex));
            y2 = stroke.y(speedMatches(sIndex));
%             distance(x1, y1, x2, y2)
            if distance(x1, y1, x2, y2) < minimumCornerDistance
                
                updatedSpeedMatches = updatedSpeedMatches(...
                    updatedSpeedMatches ~= speedMatches(sIndex));
            end
        end
        speedMatches = updatedSpeedMatches;
    end
    
%     speedMatches
    
    
    overallMatches = [curvatureMatches, speedMatches];
    
    overallMatchesSize = size(overallMatches);
    updatedOverallMatches = overallMatches;
    for i=1:overallMatchesSize(2)
        for j=1:overallMatchesSize(2)
            if i == j
                break
            end
            
            x1 = stroke.x(overallMatches(i));
            y1 = stroke.y(overallMatches(i));
            x2 = stroke.x(overallMatches(j));
            y2 = stroke.y(overallMatches(j));
            if distance(x1, y1, x2, y2) < minimumCornerDistance
                updatedOverallMatches = updatedOverallMatches(...
                    updatedOverallMatches ~= overallMatches(j));
            end
        end
        
        x1 = stroke.x(overallMatches(i));
        y1 = stroke.y(overallMatches(i));
        x2 = stroke.x(1);
        y2 = stroke.y(1);
        if distance(x1, y1, x2, y2) < minimumStartDistance
            updatedOverallMatches = updatedOverallMatches(...
                updatedOverallMatches ~= overallMatches(i));
        end
        
        x2 = stroke.x(numPoints);
        y2 = stroke.y(numPoints);
        if distance(x1, y1, x2, y2) < minimumStartDistance
            updatedOverallMatches = updatedOverallMatches(...
                updatedOverallMatches ~= overallMatches(i));
        end
    end
    overallMatches = updatedOverallMatches;
    
%     scatter(stroke.x(overallMatches), stroke.y(overallMatches))
    
    segpoints = sort(overallMatches');
    segpointsSize = size(segpoints);
    
    segtypes = zeros(segpointsSize(1) + 1, 1);

    paddedSegpoints = [1, segpoints', numPoints]'
    for i=1:segpointsSize + 1
%         i
%         paddedSegpoints(i)
%         paddedSegpoints(i+1)
%         stroke.y(paddedSegpoints(i):paddedSegpoints(i+1))
%         stroke.x(paddedSegpoints(i):paddedSegpoints(i+1))
        [b, bint, r, rint, stats] = regress(stroke.y(paddedSegpoints(i):...
            paddedSegpoints(i+1)), [ones(paddedSegpoints(i+1) - paddedSegpoints(i) + 1, 1)...
            , stroke.x(paddedSegpoints(i):paddedSegpoints(i+1))]);
        
        if stats(1) < 0.05
            segtypes(i) = 1;
        end
        
        
        
    end
    
    
    
    
    
    
    
    
    
    
    
end






















