function h = evalAll(strokes)
    % h = evalAll(strokes)
    for i = 1:length(strokes);
        disp(sprintf('stroke %i',i));
        [corners segtypes] = segmentStroke(strokes(i));
        h = showSegmentation(strokes(i),corners,segtypes);
        %h = showSegmentation(strokes(i),[]);
        hold on
        % input('click to continue');
    end
    hold off
end
            