function SpaceRocks

    rng(0);
    
    keyPressBufferN = 1000;
    keyPressBuffer = int8(zeros(1,keyPressBufferN));
    keyPressBuffer_idxInput = 1;
    keyPressBuffer_idxProcessed = 1;
    keyDownArray = false(1,4);
    
    numRocks0 = 1;
    numRocks = numRocks0;
    rockPoints = 5;
    rockSize = 0.1;
    rockSpeed = 0.05;

    yPixels = 360;
    xPixels = 640;
    xRatio = xPixels/yPixels;
    
    % Game rules
    numberOfLives0 = 3;
    numberOfLives = numberOfLives0;
    exitGame = false;
    gameMode = 0; % 0 attract, 1 spawn player, 2 play, 3 player dead, 4 spawn rocks, 5 game over
    gameEventTime = nan;
    allRocksDead = true;
    playerDead = true;
    versusDead = true;
    playerCueIndex = nan;
    
    maxRender = max(numRocks+10,10);
    renderCueStatuses = char('?'*ones(1,maxRender));
    renderCueIPVATs = NaN(maxRender,7);
    
    maxStatusRender = max(numberOfLives+10,10);
    statusRenderCueStatuses = char('?'*ones(1,maxStatusRender));
    statusRenderCueIPVATs = NaN(maxStatusRender,7);
    
    maxShapes = max(2*numRocks,10);
    shapeCueShapes = cell(1,maxShapes);
    shapeCueSimpleShapes = cell(1,maxShapes);
    shapeCueRadii = NaN(1,maxShapes);
    
    % Shape cue 1 is a pixel
    shapeCueSimpleShapes{1} = [0 0];
    shapeCueRadii(1) = -1;
    
    maxColliders = max(2*numRocks,10);
    colliderCueStatuses = NaN(1,maxColliders);
    colliderCuePs = NaN(maxColliders,2);
    
    imageBuffer = zeros(yPixels,xPixels,3);
    blankImageBuffer = imageBuffer;
    figure(1);
    hImage = image(blankImageBuffer);
    set(gca,'ydir','normal','position',[0 0 1 1],'XColor','none','YColor','none');
    set(gcf,'KeyPressFcn',@SwapFigure,'DeleteFcn',@CloseFigures, ...
        'Toolbar','none','Menubar','none','Interruptible','off');
    figure(2);
    set(gcf,'KeyPressFcn',@KeyPress,'KeyReleaseFcn',@KeyRelease,'DeleteFcn',@CloseFigures, ...
        'Toolbar','none','Menubar','none','Interruptible','off');
    figure(1);
    
    % Debug Stuff
    keyDownArrayDebug = keyDownArray;
    hTextDebug = text(gca,round(0.01*xPixels),round(0.8*yPixels),'x');
    hTextDebug.HorizontalAlignment = 'left';
    hTextDebug.VerticalAlignment = 'top';
    hTextDebug.Color = [1 0 0];
    
    frameCountDebug = [0 0];
    hTextFps = text(gca,round(0.01*xPixels),round(0.75*yPixels),'x');
    hTextFps.HorizontalAlignment = 'left';
    hTextFps.VerticalAlignment = 'top';
    hTextFps.Color = [0 1 0];
    hTextFps.FontName = 'Courier';
    hTextFps.FontWeight = 'bold';

    modeDebug = [nan nan];
    hTextMode = text(gca,round(0.01*xPixels),round(0.7*yPixels),'x');
    hTextMode.HorizontalAlignment = 'left';
    hTextMode.VerticalAlignment = 'top';
    hTextMode.Color = [0 0 1];
    hTextMode.FontName = 'Courier';
    hTextMode.FontWeight = 'bold';
    
    statusStringDebug = cell(10,1);
    hTextStatus = text(gca,round(0.01*xPixels),round(0.65*yPixels),statusStringDebug);
    hTextStatus.HorizontalAlignment = 'left';
    hTextStatus.VerticalAlignment = 'top';
    hTextStatus.Color = [0 0 1];
    
    hTextCue = text(gca,round(0.01*xPixels),round(0.15*yPixels),statusStringDebug);
    hTextCue.HorizontalAlignment = 'left';
    hTextCue.VerticalAlignment = 'top';
    hTextCue.Color = [0 1 0];
    hTextCue.FontName = 'Courier';
    hTextCue.FontWeight = 'bold';
    hTextCue.FontSize = 6;
    
    hold on;
    hVersus = plot(nan,nan,'go-');
    hold off;
    
    % Slow update timing
    updatePeriod = 0.1;
    nextUpdateTime = 1;
    
    % Slice
    totalSlice = 1/20;
    renderSlice = 0.5; % Not use, used 0.75 of total slice instead
    collisionSlice = 0.25;
    time = 0;
    timeVersusSpawn = 0;
    tic;
    
    % Sounds
    explodeNoise = ExplodeNoise;
    sound(explodeNoise);
    
    initMode = true;
    SequenceGame('I');
    RenderShapeCue;
    DetectCollisionCue;
    HandleRocks('?');
    HandlePlayer('?');
    HandleVersus('?');
    initMode = false;
    while ~exitGame
        
        startSlice = toc;
        endSlice = startSlice + totalSlice;
        endCollisionSlice = endSlice;
        endRenderSlice = endCollisionSlice - collisionSlice * totalSlice;
        time = startSlice;
        
        if ( time>=nextUpdateTime )
            
            if ( ~ishandle(hImage) )
                exitGame = true;
            end
            
            nextUpdateTime = ceil(time/updatePeriod)*updatePeriod;
            
            SequenceGame('R');
            
            if ( sum(renderCueStatuses=='?')<10 )
                % Make more shape cues if running low
                renderCueStatuses = [renderCueStatuses char('?'*ones(1,10))];
                renderCueIPVATs = [renderCueIPVATs;NaN(10,7)];
            end
            
            if ( sum(isnan(shapeCueRadii))<10 )
                shapeCueRadii = [shapeCueRadii NaN(1,10)];
                shapeCueShapes = [shapeCueShapes cell(1,maxShapes)];
                shapeCueSimpleShapes = [shapeCueSimpleShapes cell(1,maxShapes)];
            end
            
        end
            
        HandleRocks('R');
        HandlePlayer('R');
        HandleVersus('R');
        
        if ( any(shapeCueRadii<0) )
            ScaleShapeCue;
        end
        
        if ( any(renderCueStatuses == 'r' | renderCueStatuses == 'e' | renderCueStatuses == 'E' | ...
                renderCueStatuses == 'f' | renderCueStatuses == 'F' ) )
            RenderShapeCue;
        else
            if ( ishandle(hImage) )
                hImage.CData = blankImageBuffer;
                drawnow;
            end
            nextUpdateTime = time;
        end
        
        if ( any(colliderCueStatuses == -2) )
            DetectCollisionCue;
        end
            
    end
    
    function SequenceGame(command)
        
        persistent livesRenderCueIds gameOverRenderCueIds ...
            controlsRenderCueIds;
        
        switch command
            
            case 'I'
                
                % Create shapes and put them in the shape cue
                % Create body
                shape = [
                    -3 -2
                    -3 2
                    -5 4
                    5 0
                    -5 -4
                    -3 -2]/300;
                shape = fliplr(shape);
                livesShapeCueId = find(isnan(shapeCueRadii),1);
                shapeCueSimpleShapes{livesShapeCueId} = shape;
                shapeCueRadii(livesShapeCueId) = -1;
                
                % Allocate render cues for player count
                livesRenderCueIds = find(statusRenderCueStatuses=='?',numberOfLives);
                statusRenderCueStatuses(livesRenderCueIds) = 'h';
                
                % Place player shapes in upper left
                for renderIdx = 1:numberOfLives
                    statusRenderCueIPVATs(livesRenderCueIds(renderIdx),:) = [livesShapeCueId [0.05*renderIdx 0.95] 0 0 nan time];
                end
                
                % Game over render
                gameOverRenderCueIds = find(statusRenderCueStatuses=='?',2);
                
                % Create shape for "game"
                shape = [
                    0.1 0.7 %g
                    0.2 0.7
                    0.2 0.9
                    0.1 0.9
                    0.1 0.8
                    0.2 0.8
                    0.2 0.7
                    
                    0.3 0.7 %a
                    0.4 0.8
                    0.4 0.7
                    
                    0.5 0.7 %m
                    0.5 0.8
                    0.6 0.7
                    0.7 0.8
                    0.7 0.7
                    
                    0.8 0.7 %e
                    0.8 0.9
                    0.9 0.9
                    0.8 0.9
                    0.8 0.8
                    0.9 0.8
                    0.8 0.8
                    0.8 0.7
                    0.9 0.7];
                
                shape = shape - mean([min(shape,[],1);max(shape,[],1)],1);
                shape = shape + [0.5*xRatio 0.6];
                gameShapeCueId = find(isnan(shapeCueRadii),1);
                shapeCueSimpleShapes{gameShapeCueId} = shape;
                shapeCueRadii(gameShapeCueId) = -1;
                statusRenderCueStatuses(gameOverRenderCueIds(1)) = 'h';
                statusRenderCueIPVATs(gameOverRenderCueIds(1),:) = [gameShapeCueId 0 0 0 0 nan time];
                
                % Greate shape for "over"
                shape = [
                    0.2 0.7 % o
                    0.1 0.7
                    0.1 0.9
                    0.2 0.9
                    0.2 0.7
                    
                    0.3 0.7 % v
                    0.3 0.8
                    0.3 0.7
                    0.4 0.8
                    0.3 0.7
                    
                    0.5 0.7 %e
                    0.5 0.9
                    0.6 0.9
                    0.5 0.9
                    0.5 0.8
                    0.6 0.8
                    0.5 0.8
                    0.5 0.7
                    0.7 0.7
                    
                    0.7 0.8 %r
                    0.8 0.8
                    ];
                
                shape = shape - mean([min(shape,[],1);max(shape,[],1)],1);
                shape = shape + [0.5*xRatio 0.35];
                overShapeCueId = find(isnan(shapeCueRadii),1);
                shapeCueSimpleShapes{overShapeCueId} = shape;
                shapeCueRadii(overShapeCueId) = -1;
                statusRenderCueStatuses(gameOverRenderCueIds(2)) = 'h';
                statusRenderCueIPVATs(gameOverRenderCueIds(2),:) = [overShapeCueId 0 0 0 0 nan time];
                
                % Controls render
                controlsRenderCueIds = find(statusRenderCueStatuses=='?',4);
                
                % Create shape for "space"
                shape = [
                    .00 .05
                    .40 .05
                    .40 .00
                    .00 .00
                    .00 .05
                    ];
                shape = shape - mean([min(shape,[],1);max(shape,[],1)],1);
                shape = shape + [0.35*xRatio 0.35];
                newShapeCueId = find(isnan(shapeCueRadii),1);
                shapeCueSimpleShapes{newShapeCueId} = shape;
                shapeCueRadii(newShapeCueId) = -1;
                statusRenderCueStatuses(controlsRenderCueIds(1)) = 'h';
                statusRenderCueIPVATs(controlsRenderCueIds(1),:) = [newShapeCueId 0 0 0 0 nan time];
                
                % Create shape for "arrow"
                shape = [
                    .10 .00
                    .14 .00
                    .14 .05
                    .18 .05
                    .12 .10
                    .06 .05 
                    .10 .05
                    .10 .00
                    ];
                shape = shape - mean([min(shape,[],1);max(shape,[],1)],1);
                shape = shape + [0.65*xRatio 0.45];
                newShapeCueId = find(isnan(shapeCueRadii),1);
                shapeCueSimpleShapes{newShapeCueId} = shape;
                shapeCueRadii(newShapeCueId) = -1;
                statusRenderCueStatuses(controlsRenderCueIds(2)) = 'h';
                statusRenderCueIPVATs(controlsRenderCueIds(2),:) = [newShapeCueId 0 0 0 0 nan time];
                
                shape = fliplr(shape);
                shape = shape - mean([min(shape,[],1);max(shape,[],1)],1);
                shape = shape + [0.75*xRatio 0.4];
                newShapeCueId = find(isnan(shapeCueRadii),1);
                shapeCueSimpleShapes{newShapeCueId} = shape;
                shapeCueRadii(newShapeCueId) = -1;
                statusRenderCueStatuses(controlsRenderCueIds(3)) = 'h';
                statusRenderCueIPVATs(controlsRenderCueIds(3),:) = [newShapeCueId 0 0 0 0 nan time];
                
                shape(:,1) = .1 - shape(:,1);
                shape = shape - mean([min(shape,[],1);max(shape,[],1)],1);
                shape = shape + [0.55*xRatio 0.4];
                newShapeCueId = find(isnan(shapeCueRadii),1);
                shapeCueSimpleShapes{newShapeCueId} = shape;
                shapeCueRadii(newShapeCueId) = -1;
                statusRenderCueStatuses(controlsRenderCueIds(4)) = 'h';
                statusRenderCueIPVATs(controlsRenderCueIds(4),:) = [newShapeCueId 0 0 0 0 nan time];
                
            case 'R'
                
                if ( numberOfLives )
                    % Render lives shapes on the upper left corner
                    renderCueIdz = statusRenderCueStatuses(livesRenderCueIds) == 'h';
                    renderCueIdz((numberOfLives+1):end) = false;
                    if ( any( renderCueIdz ) )
                        statusRenderCueStatuses(livesRenderCueIds(renderCueIdz)) = 'r';
                    end
                end
                
                % Debug stuff
                if ( ~isequal(statusStringDebug,hTextStatus.String) )
                    hTextStatus.String = statusStringDebug;
                end
                FPS = frameCountDebug(1)/(time-frameCountDebug(2));
                frameCountDebug(1) = 0;
                frameCountDebug(2) = time;
                hTextFps.String = sprintf('%9.2f runtime %6.2f fps',time,FPS);
                if ( gameMode~=modeDebug(1) || numberOfLives~=modeDebug(2) )
                    modeDebug = [gameMode numberOfLives];
                    hTextMode.String = sprintf('GameMode %3d Lives %1d',modeDebug);
                end
                hTextCue.String = {renderCueStatuses,statusRenderCueStatuses, ...
                    sprintf('%3d',colliderCueStatuses),sprintf('%d',isfinite(shapeCueRadii))};

                if ( gameMode == 5 )
                    
                    % Render game over when in game mode 5
                    renderCueIds = statusRenderCueStatuses(gameOverRenderCueIds) == 'h';
                    if ( any(renderCueIds) )
                        statusRenderCueStatuses(gameOverRenderCueIds(renderCueIds)) = 'r';
                    end
                    
                end
                
                if ( ~isnan(gameEventTime) )
                    
                    % Do not sequence through game modes if the event delay
                    % timer is active.
                    if ( time<gameEventTime )
                        return;
                    else
                        gameEventTime = nan;
                    end
                    
                end
                
                if ( gameMode==0 )
                    
                    % Game mode 0 is attract mode which attracts players to
                    % play the game.  It displays the contorls on scren.
                    
                    if ( playerDead )
                        
                        % Refresh game parameters to initial values
                        numberOfLives = numberOfLives0;        

                        % Spawn zero rocks (clear them)
                        rockSize = 0.1;
                        numRocks = 0;
                        HandleRocks('I');
                        numRocks = numRocks0;
                        
                        % Clear versus
                        HandleVersus('C');
                        
                        % Spawn a new player, which is also controllable
                        HandlePlayer('I');

                    end
                    
                    if ( keyDownArray(4) ) % 4 is spacebar (fire)
                        
                        % Once the player fires spawn rocks to start a game
                        gameMode = 4;
                        
                    end
                    
                    % Render the controller info shape (spacebar and arrows)
                    renderCueIds = statusRenderCueStatuses(controlsRenderCueIds) == 'h';
                    if ( any(renderCueIds) )
                        statusRenderCueStatuses(controlsRenderCueIds(renderCueIds)) = 'r';
                    end
                    
                elseif ( gameMode == 1 )
                    
                    % Game mode 1 is an indestructable spawn mode.  After a
                    % delay switch from Game mode 2 (play).
                    gameMode = 2;

                elseif ( gameMode == 2 )
                    
                    % Game mode 2 is normal play
                    
                    if ( playerDead )
                        % If player dies subtract lives
                        numberOfLives = numberOfLives - 1;
                        if ( numberOfLives > 0 )
                            % If there are player lives left pause at game
                            % mode 3 (player spawn) for 3 seconds
                            gameMode = 3;
                            gameEventTime = time + 3;
                        else
                            % If there are no player lives left pause at
                            % game mode 5 (game over) for 10 seconds
                            gameMode = 5;
                            gameEventTime = time + 10;
                        end
                    elseif ( allRocksDead )
                        % If player destroys all rocks pause at game mode 4
                        % (rock spawn) for 3 seconds
                        gameMode = 4;
                        gameEventTime = time + 3;
                    else
                        if ( versusDead && time > (timeVersusSpawn+5) )
                            HandleVersus('I');
                        end
                    end
                    
                elseif ( gameMode == 3 )
                    
                    % Game mode 3 is player spawn.  Initialize a new
                    % player and pause at game mode 1 (indestructible) for 3
                    % seconds.
                    
                    HandlePlayer('I');
                    gameEventTime = time + 3;
                    gameMode = 1;
                    
                elseif ( gameMode == 4 )
                    
                    % Game mode 4 is rock spawn.  Double the number of
                    % rocks, spawn them, then then go to hame mode 2
                    % (play).
                    
                    numRocks = numRocks * 2;
                    HandleRocks('I');
                    gameMode = 2;
                    
                    timeVersusSpawn = time;
                    
                elseif ( gameMode == 5 )
                    
                    % Game mode 5 is game over.  Go to game mode 0 once the
                    % event delay timer runs out.
                    gameMode = 0;
                    
                end
                
        end

    end
        
    function HandleKeyPresses
        
        if ( keyPressBuffer_idxProcessed ~= keyPressBuffer_idxInput )
            keyIdx = keyPressBuffer(keyPressBuffer_idxProcessed);
            keyDownArray(abs(keyIdx)) = keyIdx>0;
            keyPressBuffer_idxProcessed = mod(keyPressBuffer_idxProcessed,length(keyPressBuffer))+1;
        end
        
    end

    function HandleRocks(command)

        persistent renderCueIds rockShapeIds;
        
        if ( initMode )
            clear renderCueIds rockShapeIds;
        end
        
        switch command
            
            case 'I'

                % If there are already shape cues for rocks clear it
                if ( ~isempty(renderCueIds) )
                    rockShapeIds = renderCueIPVATs(renderCueIds,1);
                    shapeCueRadii(rockShapeIds) = nan;
                    renderCueStatuses(renderCueIds) = '?';
                end
                
                if ( numRocks==0 )
                    allRocksDead = true;
                    return;
                end
                
                allRocksDead = false;
                
                % Create 3 sets of 3 random rock of large, medium, small
                rockShapeIds = find(isnan(shapeCueRadii),9);
                shapeCueLoopIdx = 1;
                for rockScale = [1 0.5 0.25]
                    for idxCueIdx = 1:3
                        % Create rock
                        shape = MakeRock(rockSize*rockScale,rockPoints);
                        shapeCueId = rockShapeIds(shapeCueLoopIdx);
                        shapeCueLoopIdx = shapeCueLoopIdx + 1;
                        shapeCueSimpleShapes{shapeCueId} = shape;
                        shapeCueRadii(shapeCueId) = -1;
                    end
                end
                
                % Allocate render cues for rocks
                renderCueIds = find(renderCueStatuses=='?',numRocks);
                for renderCueId = renderCueIds
                    
                    % Get the shape cue id
                    shapeCueId = rockShapeIds(ceil(3*rand));

                    % Add random rock position and velocity
                    randAngles = 360*rand(1,2);
                    thisRockSpeed = interp1([0 1],rockSpeed*[0.5 1.5],rand(1));
                    pv = [cosd(randAngles(1)) sind(randAngles(1)) ...
                        thisRockSpeed*[cosd(randAngles(2)) sind(randAngles(2))]];
                    pv(1:2) = 0.5*pv(1:2) + 0.5*[xRatio 1];
                    renderCueIPVATs(renderCueId,:) = [shapeCueId pv nan time];
                    
                    % Set render cue to handled
                    renderCueStatuses(renderCueId) = 'h';
                    
                end
                                                
            case 'R'
                
                if ( isempty(renderCueIds) || allRocksDead )
                    return;
                end
                
                % Check is there are any rocks left
                if ( all(renderCueStatuses(renderCueIds) == '?') )
                    allRocksDead = true;
                    return;
                end
                
                % Update render cues for rocks which have been handled
                renderCueIdz = renderCueIds(renderCueStatuses(renderCueIds) == 'h');
                dts = time - renderCueIPVATs(renderCueIdz,7);
                renderCueIPVATs(renderCueIdz,7) = time;
                renderCueIPVATs(renderCueIdz,2:3) = renderCueIPVATs(renderCueIdz,2:3) + ...
                    dts .* renderCueIPVATs(renderCueIdz,4:5);
                renderCueIPVATs(renderCueIdz,2) = mod(renderCueIPVATs(renderCueIdz,2),xRatio);
                renderCueIPVATs(renderCueIdz,3) = mod(renderCueIPVATs(renderCueIdz,3),1);
                renderCueStatuses(renderCueIdz) = 'r';
                
                % Handle exploding rocks
                renderCueIdz = renderCueIds(renderCueStatuses(renderCueIds) == 'x');
                if ( ~isempty(renderCueIdz) )
                    
                    for renderCueId = renderCueIdz
                        IPVAT = renderCueIPVATs(renderCueId,:);
                        
                        % Explode the rock
                        renderCueStatuses(renderCueId) = 'e';
                        thisRockScale = ceil(rockSize/shapeCueRadii(IPVAT(1)));
                        
                        if ( thisRockScale < 3 )
                            
                            % If the rock you blew up is big enough then
                            % split it into 2 smaller rocks
                            
                            % Figure out the size of the rock
                            idxShape1 = ceil(3*rand);
                            idxShape2 = ceil(3*rand);
                            switch thisRockScale
                                case 1
                                    idxShape1 = idxShape1+3;
                                    idxShape2 = idxShape2+3;
                                case 2
                                    idxShape1 = idxShape1+6;
                                    idxShape2 = idxShape2+6;
                            end
                            newShapeCue1 = rockShapeIds(idxShape1);
                            newShapeCue2 = rockShapeIds(idxShape2);
                            
                            % Find 2 free render cue IDs and put the 2 new
                            % rocks there
                            freeRenderCueIds = renderCueIds(renderCueStatuses(renderCueIds) == '?');
                            if ( isempty(freeRenderCueIds) )
                                freeRenderCueIds = find(renderCueStatuses == '?',2);
                                renderCueIds = [renderCueIds freeRenderCueIds];
                            elseif ( length(freeRenderCueIds)==1 )
                                renderCueStatuses(freeRenderCueIds(1)) = 'h';
                                freeRenderCueIds(end+1) = find(renderCueStatuses == '?',1);
                                renderCueIds = [renderCueIds freeRenderCueIds(end)];
                            else
                                freeRenderCueIds = freeRenderCueIds(1:2);
                            end
                            renderCueStatuses(freeRenderCueIds) = 'h';
                            
                            % Double the speed and change direction
                            velocity = IPVAT(4:5);
                            speed = norm(velocity);
                            angle0 = atan2d(velocity(2),velocity(1));
                            angle = angle0 + 45;
                            renderCueIPVATs(freeRenderCueIds(1),:) = IPVAT;
                            renderCueIPVATs(freeRenderCueIds(1),4:5) = 2*speed*[cosd(angle) sind(angle)];
                            renderCueIPVATs(freeRenderCueIds(1),1) = newShapeCue1;
                            angle = angle0 - 45;
                            renderCueIPVATs(freeRenderCueIds(2),:) = IPVAT;
                            renderCueIPVATs(freeRenderCueIds(2),4:5) = 2*speed*[cosd(angle) sind(angle)];
                            renderCueIPVATs(freeRenderCueIds(2),1) = newShapeCue2;
                        
                        end
                        
                    end
                    
                end
                
        end

    end

    function HandlePlayer(command)
        
        persistent renderCueIds rate acceleration fireButton ...
            numBullets bulletIndex bulletSpeed ...
            thrustTime thrustNoise bulletNoise ...
            colliderBulletIds colliderPlayerIds ...
            flashShape nextFlashTime ...
            fineOrientation;
        
        if ( initMode )
            
            clear renderCueIds rate acceleration fireButton ...
                numBullets bulletIndex bulletSpeed ...
                thrustTime thrustNoise bulletNoise ...
                colliderBulletIds colliderPlayerIds ...
                flashShape nextFlashTime ...
                quantizedOrientation;
            return;
            
        end
        
        switch command

            case 'I'

                playerDead = false;
                timeVersusSpawn = time;
                                        
                % Clear keydown arraykeyPressBuffer = int8(zeros(1,keyPressBufferN));
                keyPressBuffer_idxInput = 1;
                keyPressBuffer_idxProcessed = 1;
                keyDownArray = false(1,4);
                
                if ( ~isempty(renderCueIds) )
                    % Check if player as already initialized and if so skip
                    fineOrientation = 90;
                    renderCueIPVATs(renderCueIds(1),2:end) = ...
                        [0.5*[xRatio 1] 0 0 fineOrientation time];
                    renderCueStatuses(renderCueIds(1)) = 'h';
                    renderCueStatuses(renderCueIds(2)) = 'x';
                    renderCueStatuses(renderCueIds(3:end)) = 'x';
                    return;
                end                
      
                % Constants and control states
                rate = 200;
                acceleration = 0.3;
                
                % Bullet bookkeeping
                fireButton = false;
                numBullets = 3;
                bulletIndex = 1;
                bulletSpeed = 0.5;
                
                % Sounds
                thrustNoise = ThrustNoise;
                bulletNoise = BulletNoise;
                sound(thrustNoise);
                sound(bulletNoise);
                thrustTime = time;
                
                % Create shapes and put them in the shape cue
                % Create body
                shapeCueIds = find(isnan(shapeCueRadii),2);
                shape = [
                    -3 -2
                    -3 2
                    -5 4
                    5 0
                    -5 -4
                    -3 -2]/300;
                shapeCueSimpleShapes{shapeCueIds(1)} = shape;
                shapeCueRadii(shapeCueIds(1)) = -1;
                % Create thrust
                shape = [
                    -3 -2
                    -10 0
                    -3 2]/300;
                shapeCueSimpleShapes{shapeCueIds(2)} = shape;
                shapeCueRadii(shapeCueIds(2)) = -1;
                flashShape = shapeCueIds(1:2);
                
                % Allocate render cues for player and bullets
                renderCueIds = find(renderCueStatuses == '?',2+numBullets);
                fineOrientation = 90;
                renderCueIPVATs(renderCueIds(1),:) = ...
                    [shapeCueIds(1) 0.5*[xRatio 1] 0 0 fineOrientation time];
                renderCueIPVATs(renderCueIds(2),:) = ...
                    [shapeCueIds(2) nan nan nan nan nan nan];
                renderCueIPVATs(renderCueIds(3:end),1) = 1;
                
                playerCueIndex = renderCueIds(1);
                
                % Set render cue for player to handled and thrust+bullets to extra
                renderCueStatuses(renderCueIds(1)) = 'h';
                renderCueStatuses(renderCueIds(2)) = 'x';
                renderCueStatuses(renderCueIds(3:end)) = 'x';
                
                % Initialize dummy colliders to simplify logic
                colliderBulletIds = find(isnan(colliderCueStatuses),numBullets);
                colliderCueStatuses(colliderBulletIds) = -1;
                colliderPlayerIds = find(isnan(colliderCueStatuses),3);
                colliderCueStatuses(colliderPlayerIds) = -1;
                
            case 'R'
                
                if ( isempty(renderCueIds) || playerDead )
                    return;
                end
                
                if ( renderCueStatuses(renderCueIds(1)) == 'h' )
                    
                    % Disable thrust render cue to reduce collider calcs
                    if ( renderCueStatuses(renderCueIds(2)) == 'h' )
                         renderCueStatuses(renderCueIds(2)) = 'x';
                    end
                    
                    % Extract basic info
                    renderCueId = renderCueIds(1);
                    dt = time - renderCueIPVATs(renderCueId,7);
                    renderCueIPVATs(renderCueId,7) = time;
                    
                    % Handle button pushes
                    thrust = false;
                    turnLeft = false;
                    turnRight = false;
                    fireBullet = false;
                    moveEnabled = gameMode == 0 || gameMode == 1 || gameMode == 2 || gameMode == 4;
                    fireEnabled = gameMode == 1 || gameMode == 2;
                    killEnabled = gameMode == 2;
                    % Handle button pushes (Always run to clear buffer)
                    HandleKeyPresses;
                    if ( ~isequal(keyDownArray,keyDownArrayDebug) )
                        keyDownArrayDebug = keyDownArray;
                        hTextDebug.String = sprintf('%d%d%d%d',keyDownArrayDebug);
                    end
                    if ( moveEnabled )
                        if ( keyDownArray(1) )
                            turnLeft = true;
                        end
                        if ( keyDownArray(2) )
                            turnRight = true;
                        end
                        if ( keyDownArray(3) )
                            thrust = true;
                        end
                    end
                    if ( keyDownArray(4) )
                        if ( ~fireButton )
                            fireButton = true;
                            fireBullet = true;
                        end
                    else
                        fireButton = false;
                    end
                    
                    if ( turnLeft || turnRight )
                        
                        if ( turnLeft )
                            fineOrientation = fineOrientation + rate*dt;
                        end
                        if ( turnRight )
                            fineOrientation = fineOrientation - rate*dt;
                        end
                        renderCueIPVATs(renderCueId,6) = round(fineOrientation/5)*5;
                        
                    end

                    if ( thrust )
                        
                        % Accelerate
                        orientation = renderCueIPVATs(renderCueId,6);
                        accelerationVector = acceleration*[cosd(orientation) sind(orientation)];
                        renderCueIPVATs(renderCueId,4:5) = renderCueIPVATs(renderCueId,4:5) + ...
                            accelerationVector*dt;
                        
                        % Update thrust render
                        renderCueIdThrust = renderCueIds(2);
                        if ( renderCueStatuses(renderCueIdThrust) == 'x' )
                            renderCueIPVATs(renderCueIdThrust,2:end) = ...
                                renderCueIPVATs(renderCueId,2:end);
                            renderCueStatuses(renderCueIdThrust) = 'r';
                        end
                        
                        % Play thrust sound
                        if ( time>thrustTime+0.5 )
                            sound(thrustNoise);
                            thrustTime = time;
                        end
                        
                    end
                    
                    if ( fireBullet && fireEnabled )
                        
                        sound(bulletNoise);
                        
                        bulletRenderCueId = renderCueIds(2+bulletIndex);
                        bulletIndex = mod(bulletIndex,numBullets)+1;
                        
                        orientation = renderCueIPVATs(renderCueId,6);
                        position = renderCueIPVATs(renderCueId,2:3) + ...
                            10/300*[cosd(orientation) sind(orientation)];
                        velocity = renderCueIPVATs(renderCueId,4:5) + ...
                            bulletSpeed*[cosd(orientation) sind(orientation)];
                        renderCueIPVATs(bulletRenderCueId,:) = ...
                            [1 position velocity nan time];
                        
                        renderCueStatuses(bulletRenderCueId) = 'h';
                        
                    end
                    
                    % Update player and bullet renders
                    idxCueIdsReady = renderCueStatuses(renderCueIds) == 'h';
                    idxCueIdsReady(2) = 0;
                    renderCueIdsUpdate = renderCueIds(idxCueIdsReady);
                    renderCueIPVATs(renderCueIdsUpdate,2:3) = renderCueIPVATs(renderCueIdsUpdate,2:3) + ...
                        dt * renderCueIPVATs(renderCueIdsUpdate,4:5);
                    renderCueIPVATs(renderCueIdsUpdate,2) = mod(renderCueIPVATs(renderCueIdsUpdate,2),xRatio);
                    renderCueIPVATs(renderCueIdsUpdate,3) = mod(renderCueIPVATs(renderCueIdsUpdate,3),1);
                    renderCueStatuses(renderCueIdsUpdate) = 'r';
                    
                    % If player spawning make him flash
                    if ( ~killEnabled )
                        if ( time < nextFlashTime - 0.2 )
                            renderCueIPVATs(renderCueId,1) = 1;
                            renderCueIPVATs(renderCueIds(2),1) = 1;
                        elseif ( time < nextFlashTime )
                            renderCueIPVATs(renderCueId,1) = flashShape(1);
                            renderCueIPVATs(renderCueIds(2),1) = flashShape(2);
                        else
                            nextFlashTime = time + 0.4;
                        end
                    else
                        renderCueIPVATs(renderCueId,1) = flashShape(1);
                        renderCueIPVATs(renderCueIds(2),1) = flashShape(2);
                    end
                    
                    % Check if player collider hit something
                    playerHitShape = colliderCueStatuses(colliderPlayerIds)>0;
                    if ( any( playerHitShape>0 ) )
                        % Reset all player colliders
                        colliderCueStatuses(colliderPlayerIds) = -1;
                        if ( killEnabled )
                            % Make the player explode
                            renderCueStatuses(renderCueIds(1)) = 'x';
                        end
                        return;
                    end
                    
                    % Update player collider position
                    updatePlayer = colliderCueStatuses(colliderPlayerIds) == -1;
                    if ( any(updatePlayer) )
                        colliderIds = colliderPlayerIds(updatePlayer);
                        position = renderCueIPVATs(renderCueId,2:3);
                        orientation = renderCueIPVATs(renderCueId,6);
                        quantizedOrientation = round(orientation/5)*5;
                        shape = 1.01 * [ -5 4
                            5 0
                            -5 -4]/300;
                        colliderPositions = position + ...
                            [cosd(quantizedOrientation)*shape(:,1)+sind(quantizedOrientation)*shape(:,2) ...
                            sind(quantizedOrientation)  *shape(:,1)-cosd(quantizedOrientation)*shape(:,2)];
                        colliderCuePs(colliderIds,:) = colliderPositions(updatePlayer,:);
                        colliderCueStatuses(colliderIds) = -2;
                    end
                    
                    % Test if bullets hit as indicated by colliderSueStatus
                    % giving the shape that as hit
                    renderBulletIds = renderCueIds(3:end);
                    bulletsHitShape = colliderCueStatuses(colliderBulletIds)>0;
                    if ( any(bulletsHitShape) )
                        
                        % Collider IDs that hit a render cue shape
                        bulletsThatHit = colliderBulletIds(bulletsHitShape);
        
                        % Make the render cue shape that got hit explode
                        cuesThatGotHit = colliderCueStatuses(colliderBulletIds(bulletsHitShape));
                        renderCueStatuses(cuesThatGotHit) = 'x';
                        
                        % Reset the collider hit boolean
                        colliderCueStatuses(bulletsThatHit) = -1;
                        
                        % Make bullet disappear
                        renderCueStatuses(renderBulletIds(bulletsHitShape)) = 'X';
                    end
                    
                    % Update bullet collider positions
                    updateBullets = renderCueStatuses(renderBulletIds) == 'r' & ...
                        colliderCueStatuses(colliderBulletIds) == -1;
                    if ( any(updateBullets) )
                        colliderIds = colliderBulletIds(updateBullets);
                        bulletPositions = renderCueIPVATs(renderBulletIds(updateBullets),2:3);
                        colliderCuePs(colliderIds,:) = bulletPositions;
                        colliderCueStatuses(colliderIds) = -2;
                    end
                    
                elseif ( renderCueStatuses(renderCueIds(1)) == 'x' )
                    % Make player explode
                    renderCueStatuses(renderCueIds(1)) = 'f';
                    playerDead = true;
                end
                
        end
        
    end

    function HandleVersus(command)
       
        persistent renderCueIds rate acceleration bulletIndex bulletSpeed numBullets ...
            thrustNoise bulletNoise thrustTime shapeCueIds thrust ...
            colliderBulletIds colliderVersusIds versusMode versusInfo ...
            fineOrientation;
        
        if ( initMode )
            
            clear renderCueIds rate acceleration bulletIndex bulletSpeed numBullets ...
                thrustNoise bulletNoise thrustTime shapeCueIds thrust ...
                colliderBulletIds colliderVersusIds versusMode versusTime ...
                fineOrientation;
            return;
            
        end
        
        switch command
            
            case 'C'
                
                if ( ~isempty(renderCueIds) )
                    % Check if versus as already initialized and if explode
                    % it
                    versusDead = true;
                    renderCueStatuses(renderCueIds(1)) = 'f';                   
                    return;
                end
                
            case 'I'
                
                versusDead = false;
                timeVersusSpawn = time;
                versusMode = 0;

                if ( ~isempty(renderCueIds) )
                    % Check if versus as already initialized and if so skip
                    randomAng = rand(1)*360;
                    randomPos = 0.4*[cosd(randomAng) sind(randomAng)] + ...
                        0.5*[xRatio 1];
                    fineOrientation = randomAng+180;
                    renderCueIPVATs(renderCueIds(1),2:end) = ...
                        [randomPos 0 0 fineOrientation time];
                    renderCueStatuses(renderCueIds(1)) = 'h';
                    renderCueStatuses(renderCueIds(2)) = 'x';
                    renderCueStatuses(renderCueIds(3:end)) = 'x';                    
                    return;
                end
      
                % Constants and control states
                rate = 100;
                acceleration = 0.15;
                
                % Bullet bookkeeping
                bulletSpeed = 0.25;
                numBullets = 3;
                bulletIndex = 1;
                
                % Sounds
                thrustNoise = ThrustNoise;
                bulletNoise = BulletNoise;
                sound(thrustNoise);
                sound(bulletNoise);
                thrustTime = time;
                thrust = false;
                
                % Create shapes and put them in the shape cue
                % Create body
                shapeCueIds = find(isnan(shapeCueRadii),2);
                shape = [
                    -3 -2
                    -3 2
                    -5 4
                    5 0
                    -5 -4
                    -3 -2]/300*2;
                shapeCueSimpleShapes{shapeCueIds(1)} = shape;
                shapeCueRadii(shapeCueIds(1)) = -1;
                % Create thrust
                shape = [
                    -3 -2
                    -10 0
                    -3 2]/300*2;
                shapeCueSimpleShapes{shapeCueIds(2)} = shape;
                shapeCueRadii(shapeCueIds(2)) = -1;
                
                % Allocate render cues for versus and bullets
                renderCueIds = find(renderCueStatuses == '?',2+numBullets);
                randomAng = rand(1)*360;
                randomPos = 0.4*[cosd(randomAng) sind(randomAng)] + ...
                    0.5*[xRatio 1];
                fineOrientation = randomAng+180;
                renderCueIPVATs(renderCueIds(1),:) = ...
                    [shapeCueIds(1) randomPos 0 0 fineOrientation time];
                renderCueIPVATs(renderCueIds(2),:) = ...
                    [shapeCueIds(2) nan nan nan nan nan nan];
                renderCueIPVATs(renderCueIds(3:end),1) = 1;
                
                % Set render cue for versus to handled and thrust+bullets to extra
                renderCueStatuses(renderCueIds(1)) = 'h';
                renderCueStatuses(renderCueIds(2)) = 'x';
                renderCueStatuses(renderCueIds(3:end)) = 'x';
                
                % Initialize dummy colliders to simplify logic
                colliderBulletIds = find(isnan(colliderCueStatuses),numBullets);
                colliderCueStatuses(colliderBulletIds) = -1;
                colliderVersusIds = find(isnan(colliderCueStatuses),3);
                colliderCueStatuses(colliderVersusIds) = -1;
                
            case 'R'
                
                if ( isempty(renderCueIds) || versusDead )
                    return;
                end
                
                if ( renderCueStatuses(renderCueIds(1)) == 'h' )
                    
                    % Disable thrust render cue to reduce collider calcs
                    if ( renderCueStatuses(renderCueIds(2)) == 'h' )
                         renderCueStatuses(renderCueIds(2)) = 'x';
                    end
                    
                    % Extract basic info
                    renderCueId = renderCueIds(1);
                    dt = time - renderCueIPVATs(renderCueId,7);
                    renderCueIPVATs(renderCueId,7) = time;
                    
                    % Update versus and bullet renders
                    idxCueIdsReady = renderCueStatuses(renderCueIds) == 'h';
                    idxCueIdsReady(2) = 0;
                    renderCueIdsUpdate = renderCueIds(idxCueIdsReady);
                    renderCueIPVATs(renderCueIdsUpdate,2:3) = renderCueIPVATs(renderCueIdsUpdate,2:3) + ...
                        dt * renderCueIPVATs(renderCueIdsUpdate,4:5);
                    renderCueIPVATs(renderCueIdsUpdate,2) = mod(renderCueIPVATs(renderCueIdsUpdate,2),xRatio);
                    renderCueIPVATs(renderCueIdsUpdate,3) = mod(renderCueIPVATs(renderCueIdsUpdate,3),1);
                    renderCueStatuses(renderCueIdsUpdate) = 'r';

                    % Check if versus versus collider hit something
                    versusHitShape = colliderCueStatuses(colliderVersusIds)>0;
                    if ( any( versusHitShape>0 ) )
                        % Reset all versus colliders
                        colliderCueStatuses(colliderVersusIds) = -1;
                        % Make the versus explode
                        renderCueStatuses(renderCueIds(1)) = 'x';
                        return;
                    end
                    
                    % Update player collider position
                    updateVersus = colliderCueStatuses(colliderVersusIds) == -1;
                    if ( any(updateVersus) )
                        colliderIds = colliderVersusIds(updateVersus);
                        position = renderCueIPVATs(renderCueId,2:3);
                        orientation = renderCueIPVATs(renderCueId,6);
                        quantizedOrientation = round(orientation/5)*5;
                        shape = 1.01 * [ -5 4
                            5 0
                            -5 -4]/300*2;
                        colliderPositions = position + ...
                            [cosd(quantizedOrientation)*shape(:,1)+sind(quantizedOrientation)*shape(:,2) ...
                            sind(quantizedOrientation)  *shape(:,1)-cosd(quantizedOrientation)*shape(:,2)];
                        colliderCuePs(colliderIds,:) = colliderPositions(updateVersus,:);
                        colliderCueStatuses(colliderIds) = -2;
                    end
                    
                    
                    
                    
                    
                    % Versus Logic
                    thrust = false;
                    turnLeft = false;
                    turnRight = false;
                    fireBullet = false;
                    fireEnabled = gameMode == 1 || gameMode == 2;
                    if ( versusMode==0 )
                        % Get steer point as a aposition just behind Player
                        if ( ~playerDead )
                            playerIPVAT = renderCueIPVATs(playerCueIndex,:);
                            playerAngle = playerIPVAT(6);
                            pointPosition = playerIPVAT(2:3) - 0.25 * [cosd(playerAngle) sind(playerAngle)];
                            hVersus.XData = yPixels*[playerIPVAT(2) pointPosition(1)];
                            hVersus.YData = yPixels*[playerIPVAT(3) pointPosition(2)];
                            versusInfo = [time pointPosition nan];
                            versusMode = 1;
                        end
                    elseif ( versusMode==1 )
                        % Turn to steer point
                        aimPoint = versusInfo(2:3);
                        versusIPVAT = renderCueIPVATs(renderCueId,:);
                        pointVector = aimPoint - versusIPVAT(2:3);
                        pointVector = pointVector/norm(pointVector);
                        versusAngle = versusIPVAT(6);
                        versusVector = [cosd(versusAngle) sind(versusAngle)];
                        turnCos = pointVector*versusVector';
                        turnSin = pointVector(1)*versusVector(2)-pointVector(2)*versusVector(1);
                        turnAngle = atan2d(turnSin,turnCos);
                        if ( turnAngle > 0 )
                            turnRight = true;
                            if ( versusInfo(4) < 0 && abs(turnAngle) < 10 )
                                versusMode = 2;
                                versusInfo = time;
                            end
                        elseif ( turnAngle < 0 )
                            turnLeft = true;
                            if ( versusInfo(4) > 0 && abs(turnAngle) < 10 )
                                versusMode = 2;
                                versusInfo = time;
                            end
                        end
                        if ( versusMode==1 )
                            versusInfo(4) = turnAngle;
                            hVersus.XData = yPixels*[versusIPVAT(2) aimPoint(1)];
                            hVersus.YData = yPixels*[versusIPVAT(3) aimPoint(2)];
                        end
                    elseif ( versusMode==2 )
                        % Briefly fire thruster
                        versusIPVAT = renderCueIPVATs(renderCueId,:);
                        speed = norm(versusIPVAT(4:5));
                        if ( speed < 0.1 )
                            thrust = true;
                        else
                            versusMode = 3;
                            versusInfo = [time nan];
                        end
                    elseif ( versusMode==3 || versusMode==4 )
                        % Aim at player
                        if ( ~playerDead )
                            playerIPVAT = renderCueIPVATs(playerCueIndex,:);
                            versusIPVAT = renderCueIPVATs(renderCueId,:);
                            Pt = playerIPVAT(2:3) - versusIPVAT(2:3);
                            Vt = playerIPVAT(4:5) - versusIPVAT(4:5);
                            Pu = Pt/norm(Pt);
                            VtLos = (Vt*Pu')*Pu;
                            VtTan = Vt - VtLos;
                            VtTanN = norm(VtTan);
                            if ( VtTanN < bulletSpeed )
                                BtLos = Pu*sqrt(bulletSpeed^2-VtTanN^2);
                                BtTan = VtTan/VtTanN*sqrt(bulletSpeed^2-norm(BtLos)^2);
                                hVersus.XData = yPixels*(versusIPVAT(2)+[BtLos(1) 0 BtTan(1) nan 0 BtLos(1)+BtTan(1)]);
                                hVersus.YData = yPixels*(versusIPVAT(3)+[BtLos(2) 0 BtTan(2) nan 0 BtLos(2)+BtTan(2)]);
                                pointVector = BtLos + BtTan;
                                pointVector = pointVector / norm(pointVector);
                                versusAngle = versusIPVAT(6);
                                versusVector = [cosd(versusAngle) sind(versusAngle)];
                                turnCos = pointVector*versusVector';
                                turnSin = pointVector(1)*versusVector(2)-pointVector(2)*versusVector(1);
                                turnAngle = atan2d(turnSin,turnCos);
                                turnRight = turnAngle > 0;
                                turnLeft = turnAngle < 0;
                                if ( versusMode == 3 )
                                    if ( sign(turnAngle) ~= sign(versusInfo(2)) && abs(turnAngle) < 10 )
                                        versusMode = 4;
                                        versusInfo = time;
                                        fireBullet = true;
                                        turnLeft = false;
                                        turnRight = false;
                                    else
                                        versusInfo(2) = turnAngle;
                                    end
                                elseif ( versusMode == 4 )
                                    if ( bulletIndex == 1 )
                                        versusMode = 5;
                                        versusInfo = time;
                                    elseif ( time > versusInfo(1)+1 && abs(turnAngle) < 0.1 )
                                        fireBullet = true;
                                        turnRight = false;
                                        turnLeft = false;
                                        versusInfo = time;
                                    end
                                end
                            end
                        end
                    elseif ( versusMode==5 )
                        % Stop
                        versusIPVAT = renderCueIPVATs(renderCueId,:);
                        velocity = versusIPVAT(4:5);
                        if ( norm(velocity) > 0.01 )
                            pointVector = -velocity;
                            pointVector = pointVector / norm(pointVector);
                            versusAngle = versusIPVAT(6);
                            versusVector = [cosd(versusAngle) sind(versusAngle)];
                            turnCos = pointVector*versusVector';
                            turnSin = pointVector(1)*versusVector(2)-pointVector(2)*versusVector(1);
                            turnAngle = atan2d(turnSin,turnCos);
                            if ( turnAngle > 0 )
                                turnRight = true;
                            elseif ( turnAngle < 0 )
                                turnLeft = true;
                            end
                            norm(velocity)
                            if ( abs(turnAngle) < norm(velocity)*200 )
                                thrust = true;
                            end
                        else
                            versusMode = 0;
                            versusInfo = time;
                        end
                    end
                    
                    
                    if ( turnLeft || turnRight )
                        
                        if ( turnLeft )
                            fineOrientation = fineOrientation + rate*dt;
                        end
                        if ( turnRight )
                            fineOrientation = fineOrientation - rate*dt;
                        end
                        renderCueIPVATs(renderCueId,6) = round(fineOrientation/5)*5;
                        
                    end

                    if ( thrust )
                        
                        % Accelerate
                        orientation = renderCueIPVATs(renderCueId,6);
                        accelerationVector = acceleration*[cosd(orientation) sind(orientation)];
                        renderCueIPVATs(renderCueId,4:5) = renderCueIPVATs(renderCueId,4:5) + ...
                            accelerationVector*dt;
                        
                        % Update thrust render
                        renderCueIdThrust = renderCueIds(2);
                        if ( renderCueStatuses(renderCueIdThrust) == 'x' )
                            renderCueIPVATs(renderCueIdThrust,2:end) = ...
                                renderCueIPVATs(renderCueId,2:end);
                            renderCueStatuses(renderCueIdThrust) = 'r';
                        end
                        
                        % Play thrust sound
                        if ( time>thrustTime+0.5 )
                            sound(thrustNoise);
                            thrustTime = time;
                        end
                        
                    end
                    
                    if ( fireBullet && fireEnabled )
                        
                        sound(bulletNoise);
                        
                        bulletRenderCueId = renderCueIds(2+bulletIndex);
                        bulletIndex = mod(bulletIndex,numBullets)+1;
                        
                        orientation = renderCueIPVATs(renderCueId,6);
                        position = renderCueIPVATs(renderCueId,2:3) + ...
                            10/300*[cosd(orientation) sind(orientation)];
                        velocity = renderCueIPVATs(renderCueId,4:5) + ...
                            bulletSpeed*[cosd(orientation) sind(orientation)];
                        renderCueIPVATs(bulletRenderCueId,:) = ...
                            [1 position velocity nan time];
                        
                        renderCueStatuses(bulletRenderCueId) = 'h';
                        
                    end
                    
                    
                    
                    % Test if bullets hit as indicated by colliderSueStatus
                    % giving the shape that as hit
                    renderBulletIds = renderCueIds(3:end);
                    bulletsHitShape = colliderCueStatuses(colliderBulletIds)>0;
                    if ( any(bulletsHitShape) )
                        
                        % Collider IDs that hit a render cue shape
                        bulletsThatHit = colliderBulletIds(bulletsHitShape);
        
                        % Make the render cue shape that got hit explode
                        cuesThatGotHit = colliderCueStatuses(colliderBulletIds(bulletsHitShape));
                        renderCueStatuses(cuesThatGotHit) = 'x';
                        
                        % Reset the collider hit boolean
                        colliderCueStatuses(bulletsThatHit) = -1;
                        
                        % Make bullet disappear
                        renderCueStatuses(renderBulletIds(bulletsHitShape)) = 'X';
                        
                    end
                    
                    % Update bullet collider positions
                    updateBullets = renderCueStatuses(renderBulletIds) == 'r' & ...
                        colliderCueStatuses(colliderBulletIds) == -1;
                    if ( any(updateBullets) )
                        colliderIds = colliderBulletIds(updateBullets);
                        bulletPositions = renderCueIPVATs(renderBulletIds(updateBullets),2:3);
                        colliderCuePs(colliderIds,:) = bulletPositions;
                        colliderCueStatuses(colliderIds) = -2;
                    end
                    
                elseif ( renderCueStatuses(renderCueIds(1)) == 'x' )
                    % Make versus player explode
                    renderCueStatuses(renderCueIds(1)) = 'f';
                    versusDead = true;
                    timeVersusSpawn = time;
                end
                
        end
        
    end

    function ScaleShapeCue
        
        % If the shape radius is less than 0 then this is a command to
        % compute a new radius but mainly to create a high detail shape for
        % renderring
        shapeCueIds = find(shapeCueRadii<0);
        for shapeCueId = shapeCueIds
            
            shape = shapeCueSimpleShapes{shapeCueId};
            shapeCueRadii(shapeCueId) = max(sqrt(sum(shape(:,1).^2+shape(:,2).^2,2)));
            addAnotherPoint = true;
            while ( addAnotherPoint )
                addAnotherPoint = false;
                newShape = shape(1,:);
                for idxLine = 2:size(shape,1)
                    pointA = shape(idxLine-1,:);
                    pointB = shape(idxLine,:);
                    d = norm(pointB-pointA);
                    if ( d>1/yPixels )
                        newShape(end+1,:) = mean([pointA;pointB],1);
                        addAnotherPoint = true;
                    end
                    newShape(end+1,:) = pointB;
                end
                shape = newShape;
            end
            shapeCueShapes{shapeCueId} = shape;
            
        end
        
    end

    function RenderShapeCue
        
        persistent renderMode renderCueIds renderCueIdx ...
            statusRenderCueIds;
        
        if ( initMode )
            clear renderMode renderCueIds renderCueIdx ...
                statusRenderCueIds;
            return;
        end
        
        if ( isempty(renderMode) )
            
            % For the first mode select the cues which need to be
            % renderred
            renderCueIds = find(renderCueStatuses=='r' | ...
                renderCueStatuses=='e' | renderCueStatuses=='E' | ...
                renderCueStatuses=='f' | renderCueStatuses=='F');
            statusRenderCueIds = find(statusRenderCueStatuses == 'r');
            if ( ~isempty(renderCueIds) || ~isempty(statusRenderCueIds) )
                renderMode = true;
                renderCueIdx = 1;
                imageBuffer = blankImageBuffer;
                
                % There are 2 render cues, the nominal render cue and the
                % status render cue.  Each render cue is treated
                % differently when renderring.
                renderCueIds = [renderCueIds statusRenderCueIds;
                    ones(1,length(renderCueIds)) 2*ones(1,length(statusRenderCueIds))];
            end
            
        else
            
            % For the second mode loop through each render cue and render
            % it until time runs out
            
            % If time has already run out then make sure at least one cue
            % is handled on this loop
            handledOne = false;
            
            while ( toc < endRenderSlice || ~handledOne )
                
                if ( renderCueIdx > size(renderCueIds,2) )
                    % If we've reached the end of the render cue then go
                    % back to the first mode 
                    renderMode = [];
                    break;
                end
                
                % Handle the first cue so we are free to exit
                handledOne = true;
                
                % Select the next cue to render
                renderCueId = renderCueIds(1,renderCueIdx);
                renderCueCue = renderCueIds(2,renderCueIdx);
                renderCueIdx = renderCueIdx + 1;
                if ( renderCueCue==1 )
                    % For the nominal render cue get IPVAT and handle any
                    % explosions
                    IPVAT = renderCueIPVATs(renderCueId,:);
                    shape = shapeCueShapes{IPVAT(1)};
                    
                    if ( isempty(shape) )
                        disp('what?');
                    end
                    
                    if ( renderCueStatuses(renderCueId)=='r' )
                        renderCueStatuses(renderCueId)='h';
                    elseif ( renderCueStatuses(renderCueId)=='e' | ...
                            renderCueStatuses(renderCueId)=='f' )
                        % If the status is set to 'e' start the explode
                        % animation
                        sound(explodeNoise);
                        renderCueStatuses(renderCueId) = upper(renderCueStatuses(renderCueId));
                    elseif ( renderCueStatuses(renderCueId)=='E' | ...
                            renderCueStatuses(renderCueId)=='F' )
                        % During the explode animation scale the shape for 0.5
                        % seconds
                        timeSinceExplode = time-IPVAT(7);
                        scale = 1 + 10*timeSinceExplode;
                        shape = scale*shape;
                        if ( timeSinceExplode > 0.5 )
                            if ( renderCueStatuses(renderCueId)=='E' )
                                renderCueStatuses(renderCueId)='?';
                            elseif ( renderCueStatuses(renderCueId)=='F' )
                                renderCueStatuses(renderCueId)='y';
                            end
                        end
                        
                        if ( isempty(shape) )
                            disp('huh?');
                        end
                        
                    end
                elseif ( renderCueCue==2 )
                    % For the status render cue get IPVAT
                    IPVAT = statusRenderCueIPVATs(renderCueId,:);
                    shape = shapeCueShapes{IPVAT(1)};
                    
                    if ( statusRenderCueStatuses(renderCueId)=='r' )
                        statusRenderCueStatuses(renderCueId)='h';
                    end
                    
                    if ( isempty(shape) )
                        disp('whoah?');
                    end
                end
                
                % Render the high-resolution shape accounting for
                % orientation
                position = IPVAT(2:3);
                orientation = IPVAT(6);
                if ( ~isnan(orientation) )
                    shape = [cosd(orientation)*shape(:,1)+sind(orientation)*shape(:,2) ...
                        sind(orientation)*shape(:,1)-cosd(orientation)*shape(:,2)];
                end
                pixelPositions = yPixels*(position + shape);
                pixelPositions = round(pixelPositions);
                pixelPositions(:,1) = mod(pixelPositions(:,1)-1,size(imageBuffer,2))+1;
                pixelPositions(:,2) = mod(pixelPositions(:,2)-1,size(imageBuffer,1))+1;

                % Convert the picel positions to image index colors
                [idxR,idxG,idxB] = IndexToIndex(imageBuffer,pixelPositions(:,1),pixelPositions(:,2));

                if ( renderCueCue==1 )
                    imageBuffer(idxR) = 255;
                    imageBuffer(idxG) = 255;
                    imageBuffer(idxB) = 255;
                elseif ( renderCueCue==2 )
                    imageBuffer(idxG) = 255;
                end
                
            end
            if ( ishandle(hImage) )
                hImage.CData = imageBuffer;
                drawnow;
                
                frameCountDebug(1) = frameCountDebug(1) + 1;

            end
            
        end
  
    end

    function DetectCollisionCue
        
        persistent collisionMode colliderIds colliderPs ...
            renderCueIds renderCueIPATs renderCueIdx;
        
        if ( initMode )
            clear collisionMode colliderIds colliderPs ...
                renderCueIds renderCueIPATs renderCueIdx;
            return;
        end
        
        if ( isempty(collisionMode) )
            
            % For the first mode select the collider cues which have a
            % collision test requested as indicated by a status of -2
            colliderIds = find(colliderCueStatuses==-2);
            colliderPs = colliderCuePs(colliderIds,:);   
            
            % Find all render cues whose geometries have been recently
            % updated
            renderCueIds = find(renderCueStatuses=='r' | renderCueStatuses=='h');
            renderCueIdx = 1;
            renderCueIPATs = renderCueIPVATs(renderCueIds,[1 2 3 6 7]);
            if ( ~isempty(colliderPs) )
                collisionMode = true;
            end
            
        else
            
            % For the second mode loop through each render cue and test all
            % collision cues.  The loops are done this way because the
            % matlab inpolygon function can work on all colliders
            % simultaneously.
            
            % If time has already run out then make sure at least one cue
            % is handled on this loop
            handledOne = false;
            
            while ( toc < endCollisionSlice || ~handledOne )
                
                if ( renderCueIdx > length(renderCueIds) )
                    % If we've reached the end of the render cue then go
                    % back to the first mode 
                    colliderCueStatuses(colliderCueStatuses==-2) = -1;
                    collisionMode = [];
                    break;
                end
                
                % Handle the first cue so we are free to exit
                handledOne = true;
                
                % Get position information about the shape for which a
                % collision test is to be made
                shapeId = renderCueIPATs(renderCueIdx,1);
                shapeP = renderCueIPATs(renderCueIdx,2:3);
                shapeA = renderCueIPATs(renderCueIdx,4);
                shapeR = shapeCueRadii(shapeId);
                renderCueIdx = renderCueIdx + 1;
                
                % Test the shape only if it is within the shape radius of
                % any colliders
                dP = colliderPs-shapeP;
                r = sqrt(dP(:,1).^2+dP(:,2).^2);
                if ( any(r<shapeR) )
                    % Get the simple shape and orientation
                    shape = shapeCueSimpleShapes{shapeId};
                    orientation = shapeA;
                    if ( ~isnan(orientation) )
                        shape = [cosd(orientation)*shape(:,1)+sind(orientation)*shape(:,2) ...
                            sind(orientation)*shape(:,1)-cosd(orientation)*shape(:,2)];
                    end
                    % Use the built-in matlab function to test if a point
                    % is within a polygon
                    hits = inpolygon(dP(:,1),dP(:,2),shape(:,1),shape(:,2));
                    if ( any(hits) )
                        hitCollider = colliderIds(hits);
                        colliderCueStatuses(hitCollider) = renderCueIds(renderCueIdx-1);
                        statusStringDebug{end+1} = sprintf('Collider %d hit Render Cue %d',hitCollider(1), ...
                            renderCueIds(renderCueIdx-1));
                        statusStringDebug(1) = [];
                    end
                end

            end
             
        end
        
    end

    function KeyPress(~,event)
        
        keyIndex = nan;
        switch event.Key
            case 'leftarrow'
                keyIndex = 1;
            case 'rightarrow'
                keyIndex = 2;
            case 'uparrow'
                keyIndex = 3;
            case 'space'
                keyIndex = 4;
        end
        if ( ~isnan(keyIndex) )
            keyPressBuffer(keyPressBuffer_idxInput) = keyIndex;
            keyPressBuffer_idxInput = mod(keyPressBuffer_idxInput,keyPressBufferN) + 1;
        end

    end

    function KeyRelease(~,event)

        keyIndex = nan;
        switch event.Key
            case 'leftarrow'
                keyIndex = -1;
            case 'rightarrow'
                keyIndex = -2;
            case 'uparrow'
                keyIndex = -3;
            case 'space'
                keyIndex = -4;
        end
        if ( ~isnan(keyIndex) )
            keyPressBuffer(keyPressBuffer_idxInput) = keyIndex;
            keyPressBuffer_idxInput = mod(keyPressBuffer_idxInput,keyPressBufferN) + 1;
        end
        
    end

    function SwapFigure(obj,event)
        
        Position = obj.Position;
        figure(2);
        Position(2) = Position(2) + Position(4);
        Position(3) = min(Position(3),240);
        Position(4) = 0;
        set(gcf,'Position',Position,'Color','None');
        
    end

    function CloseFigures(~,~)
        
        figure(1);
        delete(gcf);
        figure(2);
        delete(gcf);
        
    end

end

function [idxR,idxG,idxB] = IndexToIndex(pixels,i2,i1)

    iz = zeros(size(i1));
    if (isempty(iz))
        idxR = nan;
        idxG = nan;
        idxB = nan;
        return;
    end
    sizePixels = size(pixels);
    i3 = iz+1;
    idxR = i1 + (i2-1)*sizePixels(1) + (i3-1)*sizePixels(1)*sizePixels(2);
    i3 = iz+2;
    idxG = i1 + (i2-1)*sizePixels(1) + (i3-1)*sizePixels(1)*sizePixels(2);
    i3 = iz+3;
    idxB = i1 + (i2-1)*sizePixels(1) + (i3-1)*sizePixels(1)*sizePixels(2);
    
end

function thrustNoise = ThrustNoise()

    fs = 8192;
    dt = 1/fs;
    T = 0.5;
    t= 0:dt:T;
    freq = 2000;
    ydNoise = zeros(size(t));
    flipFlop = true;
    timeFlipFlop = 0;
    magFlipFlop = randn(1);
    for idx = 1:length(t)
        time = t(idx);
        dtf = 1/freq;
        if (time-timeFlipFlop) >= dtf
            flipFlop = ~flipFlop;
            timeFlipFlop = timeFlipFlop+dtf;
            magFlipFlop = 0.5+0.5*randn(1);
        end
        ydNoise(idx) = 0.05*magFlipFlop*double(flipFlop);
    end
    thrustNoise = ydNoise;
    
end

function bulletNoise = BulletNoise()

    dt = 1/8192;
    T = 0.25;
    t= 0:dt:T;
    f0 = 1500;
    f1 = 500;
    ydNoise = zeros(size(t));
    flipFlop = true;
    timeFlipFlop = 0;
    magFlipFlop = 1;
    for idx = 1:length(t)
        time = t(idx);
        freq = f0 + (f1-f0)*time/T;
        dtf = 1/freq;
        if (time-timeFlipFlop) >= dtf
            flipFlop = ~flipFlop;
            timeFlipFlop = timeFlipFlop+dtf;
            magFlipFlop = (T-time)/T;
        end
        ydNoise(idx) = magFlipFlop*double(flipFlop);
    end
    bulletNoise = ydNoise;
    
end

function explodeNoise = ExplodeNoise()

    dt = 1/8192;
    T = 1;
    t= 0:dt:T;
    f0 = 500;
    f1 = 300;
    interpPoints = [0 randn(1)];
    time = 0;
    impulseT = 0.01;
    flipFlop = 1;
    while (time<=T)
        freq = f0 + (f1-f0)*time/T;
        dtf = 1/freq;
        time = time+dtf;
        if ( time<impulseT )
            interpPoints(end+1,:) = [time flipFlop];
            flipFlop = -flipFlop;
        else
            amplitude = 1 - (time-impulseT)/(T-impulseT);
            interpPoints(end+1,:) = [time amplitude*randn(1)];
        end
    end
    interpPoints(end+1,:) = [time+dt 0];
    interpPoints(end+1,:) = [T 0];
    explodeNoise = 2*interp1(interpPoints(:,1),interpPoints(:,2),t);
    
end

function shape = MakeRock(rockSize,rockPoints)

    angles = (0:rockPoints)'*360/rockPoints;
    shape = [cosd(angles) sind(angles)];
    shape = shape + 0.1*randn(rockPoints+1,2);
    shape(end,:) = shape(1,:);
    shape = rockSize * shape;
    
end