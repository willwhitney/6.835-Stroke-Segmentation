function h = showSegmentation(stroke,segpoints,segtypes)
    %h = showSegmentation(x,y,segpoints)
    start = 1;
    hold on
    color = [0 0 0];
    lineColor = [.8 .8 1];
    curveColor = [1 .8 .8];
    segpoints = sort(segpoints);
    ctr =1;
    for i = [segpoints' length(stroke.x)-1]
        if (exist('segtypes','var'))
            if (segtypes(ctr) == 0)
                hplot = plot([stroke.x(start),stroke.x(i+1)],...
                    [stroke.y(start),stroke.y(i+1)],'r-');
                set(hplot,'Color',lineColor);
            else
                [xc yc re a] = circfit(stroke.x(start:i+1),...
                    stroke.y(start:i+1));
                disloc1 = [stroke.x(start) stroke.y(start)] - [xc yc];
                disloc2 = [stroke.x(i+1) stroke.y(i+1)] - [xc yc];
                midpoint = floor(0.5 * (start+i));
                dislocmid = [stroke.x(midpoint) stroke.y(midpoint)]-[xc yc];
                th1 = mod(atan2(disloc1(2),disloc1(1)),2*pi);
                th2 = mod(atan2(disloc2(2),disloc2(1)),2*pi);
                thmid = mod(atan2(dislocmid(2),dislocmid(1)),2*pi);
                thmin = min([th1 th2]);
                thmax = max([th1 th2]);
                if (thmid > thmin & thmid < thmax)
                    th = linspace(thmin,thmax,500);
                else
                    th = linspace(thmax,2*pi+thmin,500);
                end
                hplot = plot(re * cos(th) + xc, re * sin(th) + yc,'r-');
                set(hplot,'Color',curveColor);
            end
            set(hplot,'LineWidth',10);
            ctr = ctr+1;
        end
        h = scatter(stroke.x(start:i+1),stroke.y(start:i+1),'.');
        if (start ~= 1)
            scatter(stroke.x(start),stroke.y(start),200,'ok');
        end


        start=i+1;
        color = mod(color + [.2 .45 .85],1);
        set(h,'CData',color);
    end
    hold off
    h = get(h,'Parent');
    axis square
end