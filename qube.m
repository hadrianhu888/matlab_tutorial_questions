function Qube_mzip
    %   MATLAB zip file, a self-extracting MATLAB archive.
    %   Usage: Run this file to recreate the original directory.

    fname = mfilename;
    fin = fopen([fname '.m'], 'r');
    dname = fname(1:find(fname == '_', 1, 'last') - 1);
    mkdir(dname);
    mkdir([dname filesep 'lib'])

    L = fgetl(fin);

    while length(L) < 2 || ~isequal(L(1:2), '%%')
        L = fgetl(fin);
    end

    while ~isequal(L, '%% EOF')
        F = [dname filesep L(4:end)];
        disp(F)
        fout = fopen(F, 'w');
        L = fgetl(fin);

        while length(L) < 2 || ~isequal(L(1:2), '%%')
            fprintf(fout, '%s\n', L);
            L = fgetl(fin);
        end

        fclose(fout);
    end

    fclose(fin);
    addpath(dname)
    addpath([dname filesep 'lib'])
end

%% Q0.m
function Q = Q0(arg, ~)
    % Q0(n), initial n^3 solved cube, default n qstate('nstr').

    q0 = 0.85 * qzero;

    if nargin == 1
        n = str2double(arg);
    else
        n = str2double(qstate('nstr'));
    end

    m = n - 1;
    mn = m + (n == 1);

    p = 0;
    Q.V = cell(n, n, n); % Vertices
    Q.C = cell(n, n, n); % Colors for color mode.

    for z = -m:2:m %^

        for y = -m:2:m

            for x = -m:2:m
                p = p + 1;
                Q.V{p} = q0 + [x y z];
                Q.C{p} = (mn - [-z y x]) / (2 * mn);
            end

        end

    end

    if n == 1
        Q.C{1} = .5 * [1 .95 .9];
    end

    if nargin == 2
        Qshow(Q)
        qstate('Q', Q)
    end

end

%% Q2026.m
function Q2026(arg, ~)

    if isequal(arg.String, 'Q20')
        S = "R L U2 F U' D F2 R2 B2 L U2 F' B' U R2 D F2 U R2 U";
    else
        S = "U U F U U R' L F F U F' B' R L U U R U D' R L' D R' L' D D";
    end

    Qpush(S)
end

%% Qfigure.m
function Qfigure
    % Initialize figure window for Qube
    clf
    shg
    sze = get(0, 'screensize');
    set(gcf, 'position', [20 40 sze(3) - 40 sze(4) - 80]);
    fclose('all');
    set(gcf, 'name', 'Qube', ...
        'numbertitle', 'off', ...
        'toolbar', 'none', ...
        'menubar', 'none', ...
        'color', 0.65 * [1 1 1], ...
        'inverthardcopy', 'off', ...
        'paperpositionmode', 'auto', ...
        'userdata', {})
    gps = get(gcf, 'pos');
    font = floor(gps(4) / 40);
    qstate('font', font)
    set(gca, 'position', [3/8 7/24 1/2 1/2], ...
        'vis', 'on', ...
        'clipping', 'off', ...
        'userdata', eye(4, 4))
    initaxis(3)
end

%% Qinit.m
function Qinit
    u = 60;
    alfa = 'LRUDFBXYZ'; % Singmaster alphabet

    for j = 1:9
        x = 4 * j + 2 * (j > 6) + 8;
        pushbut([alfa(j) ' '], [x 6 3 3] / u, @key)
        pushbut([alfa(j) ''''], [x 2 3 3] / u, @key)
    end

    pushbut("<=", [2 2 6 3] / u, @bs)
    toggbut("<==", [2 6 6 3] / u, @unscramble)
    toggbut("color", [2 30 6 3] / u, @modecb)
    pushbut("n", [2 26 6 3] / u, @nstrcb)
    pushbut("speed", [2 22 6 3] / u, @speedcb)
    pushbut("types", [2 18 6 3] / u, @typescb)
    toggbut("metric", [2 14 6 3] / u, @Qmetric)

    pushbut("=>", [53 2 6 3] / u, @randdo)
    toggbut("==>", [53 6 6 3] / u, @scramble)
    pushbut("scram", [53 10 6 3] / u, @scramcb)

    pushbut("info", [2 50 6 3] / u, @infocb)
    pushbut("apply", [53 22 6 3] / u, @apply)
    toggbut("viz", [53 18 6 3] / u, @Qviz)
    pushbut("Q26", [53 26 6 3] / u, @Q2026)
    pushbut("Q0", [53 30 6 3] / u, @Q0)
    pushbut("start", [53 42 6 3] / u, @Start)
    toggbut("solve", [53 38 6 3] / u, @Qsolve)
    toggbut("order", [53 34 6 3] / u, @Qorder)

    pushbut("ops2", [53 54 6 3] / u, @ops2)
    pushbut("ops1", [2 54 6 3] / u, @ops1)
    textbut("score", [53 50 6 3] / u, "score")
    pushbut(" ", [9 54 43 3] / u, @stacker)
    framed_mat([2 36 18 11] / u)

    tooltips
    rng('shuffle')
end

%% Qinv.m
function x = Qinv(x)
    x = split(strip(x))';
    x = x + "_";
    x = erase(x, "'_");
    x = replace(x, "_", "'");
    x = replace(x, "2'", "2");
    x = flip(x);
    x = join(x);
end

%% Qmetric.m
function Qmetric(arg, ~)
    arg.String = ['1/' num2str(4 - 2 * arg.Value)];

    if arg.Value == 1
        set(findobj('string', 'Q26'), 'string', 'Q20')
    else
        set(findobj('string', 'Q20'), 'string', 'Q26')
    end

end

%% Qmove.m
function Q = Qmove(op, Qin)
    [ax, f, sig] = axfsig(op);
    speed = qstate('speed');
    % Fractional steps.
    if speed > 0

        for j = 1:90 / speed
            R = Rk(ax, sig * j * speed);
            Q = Qrot(Qin, ax, f, R);
            Qshow(Q)
            drawnow

            if qstate('gif') == 1
                gif_frame
            elseif ~isempty(qstate('video'))
                video_frame
            end

        end

    end

    % Full quarter turn, +/- 90 degrees.
    qstate('Q', Qin)
    Q = quarter(ax, f, sig, Qin);
    Qshow(Q)

    if length(f) < 3
        Qscore(Q)
    end

end

%% Qnorm.m
function nrm = Qnorm(X, Y)
    % Qnorm(X,Y) = sum of singular values of X-Y.
    % Also known as nuclear norm.
    ncube = str2double(qstate('nstr')) ^ 3;
    nrm = 0;

    for p = 1:ncube
        nrm = nrm + sum(svd(X.V{p} - Y.V{p}));
    end

end

%% Qorder.m
function norms = Qorder(arg, ~)
    % Qorder  Number of repetitions to return to Q0
    if nargin == 0
        arg = findobj('string', 'order');
        arg.Value = 1;
    end

    v = arg.Value;
    arg.BackgroundColor = 1 - v * [.70 .25 .07];
    ops1 = findobj('callback', @ops1);
    ops2 = findobj('callback', @ops2);
    ops1.String = '0';
    ocount = 0;
    ops2.String = int2str(ocount);
    Qshow(Q0)
    qstate('Q', Q0)
    nrm = inf;
    norms = nrm;

    while nrm > 0 && arg.Value > 0
        apply
        nrm = Qnorm(qstate('Q'), Q0);
        norms(end + 1, 1) = nrm;
        ocount = ocount + 1;
        ops2.String = int2str(ocount);
        drawnow
    end

    arg.Value = 0;
    arg.BackgroundColor = 'w';
end

%% Qpush.m
function Qpush(ops)
    % Push ops onto stack.
    ops = split(string(ops));

    for k = 1:length(ops)
        push([char(ops(k)) ' '])
    end

end

%% Qrot.m
function Q = Qrot(Q, ax, f, R)
    % Q = Qrot(Q,ax,f,R)
    % Apply rotation R, face f, axis ax
    % to all the cubelets in Q.
    n = size(Q.V, 1);

    switch ax
        case 'x'

            for j = 1:n

                for k = 1:n

                    for i = f
                        Q.V{i, j, k} = Q.V{i, j, k} * R;
                    end

                end

            end

        case 'y'

            for j = 1:n

                for k = 1:n

                    for i = f
                        Q.V{k, i, j} = Q.V{k, i, j} * R;
                    end

                end

            end

        case 'z'

            for j = 1:n

                for k = 1:n

                    for i = f
                        Q.V{k, j, i} = Q.V{k, j, i} * R;
                    end

                end

            end

    end

end

%% Qscore.m
function Qscore(Q)
    counter = findobj('tag', 'ops1');
    scorer = findobj('tag', 'score');
    nrm = Qnorm(Q, Q0);

    if ~isempty(counter)
        counter.Value = counter.Value + 1;
        counter.String = num2str(counter.Value);
    end

    if ~isempty(scorer)
        scorer.String = sprintf('%7.2f', round(nrm, 2));
        scorer.FontName = 'Lucisa Sans Typewriter';
        scorer.FontWeight = 'bold';
    end

end

%% Qshow.m
function Qshow(Q)
    % Qshow(Q)  Display Q.  Default qstate('Q')

    if nargin == 0
        Q = qstate('Q');
        n = size(Q.V, 1);
        initaxis(n)
    end

    F = [1 5 7 3
         3 7 8 4
         1 3 4 2
         2 4 8 6
         1 2 6 5
         5 6 8 7];

    C = [1 3/5 0 % orange
         0 3/4 0 % green
         3/4 0 0 % red
         1 1 1 % white
         0 0 3/4 % blue
         1 1 0]; % yellow

    gps = get(gcf, 'pos');
    lw = 0.5 + (gps(4) > 400);
    set(gca, 'userdata', Q)
    rubik = isequal(qstate('mode'), 'rubik');

    cla
    n = size(Q.V, 1);
    m = n - 1;
    p = 0;

    for z = -m:2:m

        for y = -m:2:m

            for x = -m:2:m
                p = p + 1;
                type = nnz(floor([x y z])) + max(0, abs(m) - 3);
                alfa = 1.;

                if types(type) && p <= numel(Q.V)

                    if rubik

                        for k = 1:6
                            patch( ...
                                Vertices = Q.V{p}, ...
                                Faces = F(k, :), ...
                                FaceColor = C(k, :), ...
                                FaceAlpha = alfa, ...
                                LineWidth = lw);
                        end

                    else
                        patch( ...
                            Vertices = Q.V{p}, ...
                            Faces = F, ...
                            FaceColor = Q.C{p}, ...
                            FaceAlpha = alfa, ...
                            LineWidth = lw);
                    end

                end

                if qstate('gif') == 2
                    drawnow
                    gif_frame
                end

            end

        end

    end

end

%% Qsolve.m
function x = Qsolve(~, ~)
    % Breadcrumbs algorithhm.
    x = Qinv(qstate('stack'));
    unscramble
    Qpush(x)
end

%% Qube.m
function Qube(~)
    %  Linear algebra and computer science power Rubik/Color Qube.
    %  Most recent edit: '6-February-2023, 22:15'
    %
    %  L R U D F B X Y Z: Rotate clockwise,
    %           Left, Right, Up, Down, Front, Back, x, y, z axes.
    %   '  :    Rotate counter-clockwise.
    %
    %  <=  :    Apply inverse of most recent rotation.
    %  <== :    Unscramble with repeated <= 's.
    %  =>  :    One random rotation.
    %  ==> :    Scramble with scram =>'s.
    %
    %  mode:    Rubik, Color Cube.
    %  n:       nxnxn cube.
    %  speed:   Fractional rotation degrees.
    %  types:   Center=0, face=1, edge=2, corner=3.
    %  metric:  Quarter- or half-turn metric.
    %  scram:   Scramble count.
    %
    %  order:   Number of rotations to return to Q0.
    %  solve:   Breadcrumbs algorithm.
    %  restart: Complete restart.
    %  viz:     Visibility of gui controls.
    %  apply:   Apply stack.
    %  op:      One of the keys, followed by a blank, a prime or a 2.
    %  ops1:    Total number of ops.
    %  ops2:    Order or solve op count.
    %  stack:   String of ops displayed in a window above the cube.
    %
    %  Q:       Cube, 3x3x3 array of 8x3 vertices of cubelets.
    %  Q0:      Initial cube showing a single color on each face.
    %  Q20:     Superflip, half-turn max scramble.
    %  Q26:     Superflip * fourspot, quarter-turn max scramble.
    %  score:   Nuclear norm = sum of svd(Q{j}-Q0{j}).
    %
    %  info:    https://blogs.mathworks.com/cleve/2022/ ...
    %               02/13/rubiks-cube
    %               04/04/digital-simulation-of-rubiks-cube
    %               04/12/digital-simulation-of-rubiks-cube-with-Qube
    %               05/04/qube-the-movie
    %               05/18/rotation-matrices
    %               12/09/color-cube-meets-rubiks-cube

    %    Copyright 2022-2023 Cleve Moler

    Qfigure
    Qinit
    Qshow(Q0)
end

%% Qviz.m
function Qviz(arg, ~)

    if nargin == 2
        av = arg.Value;
    else
        av = arg;
        arg = findobj('callback', @Qviz);
        arg.Value = av;
    end

    uic = findobj('type', 'uicontrol');

    if av == 1
        set(uic(2:end), 'vis', 'off')
        set(uic(3), 'pos', [0.15 0.90 0.8333 0.05])
        set(arg, 'vis', 'on', ...
            'pos', [.96 .02 .02 .03], ...
            'style', 'toggle', ...
            'background', .65 * [1, 1, 1], ...
            'string', '')
        set(uic(8), 'vis', 'on', ...
            'pos', [.02 .02 .02 .03], ...
            'background', .65 * [1, 1, 1])
        qstate('rpm', 10)
    else
        set(uic, 'vis', 'on')
        set(uic(3), 'pos', [0.15 0.90 0.7167 0.05])
        set(arg, 'vis', 'on', ...
            'pos', [.8833 .30 .10 .05], ...
            'style', 'toggle', ...
            'background', [1, 1, 1], ...
            'string', 'viz')
        set(uic(8), 'vis', 'on', ...
            'pos', [.8833 .6333 .10 .05], ...
            'background', 'w')
    end

end

%% Rk.m
function R = Rk(ax, d)
    % Rk(ax,d), Rotation by d degrees about the x-, y- or z-axis.
    c = cosd(d);
    s = sind(d);

    switch ax
            case 'x', R = [1 0 0
                         0 c s
                         0 -s c];
            case 'y', R = [c 0 s
                         0 1 0
                         -s 0 c];
            case 'z', R = [c s 0
                         -s c 0
                         0 0 1];
    end

    fmat = findobj('tag', 'fmat');

    if ~isempty(fmat)
        fmat.String = mat3(R);
    end

end

%% Start.m
function Start(~, ~)
    Qube
end

%% lib\apply.m
function apply(Qxx, ~)

    if nargin == 1
        len = str2double(Qxx(2:3));
    else
        len = 3;
    end

    stk2 = blanks(0);

    while ~isempty(peek)
        stk2 = [stk2 pop];
    end

    Q = qstate('Q');
    %Qshow(Q)
    ops1 = findobj('callback', @ops1);

    while ~isempty(stk2)
        tp = top(stk2);
        op = stk2(tp);
        stk2(tp) = [];
        Q = Qmove(op, Q);
        Qshow(Q)
        drawnow
        drawnow
        push(op)
        show_stack(qstate('stack'))
    end

    qstate('Q', Q)
end

%% lib\axfsig.m
function [ax, f, sig] = axfsig(op)
    % [ax,f,sig] = axfsig(op), ax-th axis, f-th face, sig sign.
    W = ["L" "M" "R" "X"
         "F" "S" "B" "Y"
         "D" "E" "U" "Z"];
    opsm = 'RFUYZSE';
    n = str2double(qstate('nstr'));
    [ax, f] = find(op(1) == W);
    ax = char('w'+ax);

    if f == 3
        f = n;
    elseif f == 4
        f = 1:n;
    end

    if op(2) == ' '
        sig = 1;
    elseif op(2) == ''''
        sig = -1;
    else
        sig = 2;
    end

    if any(op(1) == opsm)
        sig = -sig;
    end

end

%% lib\bs.m
function bs(~, ~)
    % bs, backspace, inverse of first op in stack
    op = pop;

    if ~isempty(op)
        Q = qstate('Q');
        opt = prime(op);
        Q = Qmove(opt, Q);
        qstate('Q', Q)
        % qstate('stack2',[qstate('stack2') op])
    end

end

%% lib\dpmcb.m
function dpmcb(arg, ~)
    % dpm, degrees  per fractional rotation.
    if nargin == 0
        arg = findobj('callback', @dpmcb);
    end

    switch arg.String
        case '90', dpm = '0';
        case '30', dpm = '90';
        case '10', dpm = '30';
        case '3', dpm = '10';
        case '1', dpm = '3';
        case '0', dpm = '1';
        otherwise , dpm = '10';
    end

    arg.String = dpm;
    qstate('dpm', str2double(dpm))
    Qshow(qstate('Q'))
    set(findobj('callback', @dpmcb), 'string', dpm)
end

%% lib\fmat.m
function fmat(R)
    fmatt = findobj('tag', 'fmat');

    if ~isempty(fmatt)
        fmatt.String = mat3(R);
    end

end

%% lib\framed_mat.m
function framed_mat(pos)
    fs = qstate('font');

    if fs > 7
        fs = fs;
    elseif fs < 12
        fs = fs;
    end

    uicontrol( ...
        'style', 'frame', ...
        'units', 'normalized', ...
        'position', pos, ...
        'backgroundcolor', 0.25 * [1 1 1])
    del = .0015;
    uicontrol( ...
        'style', 'text', ...
        'units', 'normalized', ...
        'position', pos + [del del -2 * del -2 * del], ...
        'fontname', 'Lucida Sans Typewriter', ...
        'fontsize', fs, ...
        'fontweight', 'bold', ...
        'horizontalalignment', 'left', ...
        'backgroundcolor', 'w', ...
        'string', mat3(eye(3, 3)), ...
        'tag', 'fmat')
end

%% lib\infocb.m
function infocb(arg, ~)

    if nargin == 0
        arg = findobj('callback', @infocb);
    end

    switch arg.String
        case '04/12'
            blog = ['https://blogs.mathworks.com/cleve/2022/' ...
                    '04/12/digital-simulation-of-rubiks-cube-with-Qube'];
            web(blog)
            s = 'help';
        case '05/04'
            blog = ['https://blogs.mathworks.com/cleve/2022/' ...
                    '05/04/qube-the-movie'];
            web(blog)
            s = '04/12';
        case '12/09'
            blog = ['https://blogs.mathworks.com/cleve/2022/' ...
                    '12/09/color-cube-meets-rubiks-cube'];
            web(blog)
            s = '05/04';
        otherwise
            helpwin('Qube')
            s = '12/09';
    end

    arg.String = s;
end

%% lib\initaxis.m
function initaxis(n)
    axis((n + 0.5) * [-1 1 -1 1 -1 1]);
    axis off
    axis vis3d
    view(3)
    rotate3d on
    set(gca, 'clipping', 'off', ...
        'userdata', n)
end

%% lib\key.m
function key(arg, ~)

    if nargin == 2
        op = arg.String;
    else
        op = arg;
    end

    Q = qstate('Q');
    Q = Qmove(op, Q);
    push(op)
    qstate('Q', Q)
end

%% lib\mat3.m
function txt = mat3(M)
    txt = newline;

    for k = 1:3

        for j = 1:3

            if M(k, j) == 0
                txt = [txt sprintf('%6.0f', abs(M(k, j)))];
            elseif M(k, j) == round(M(k, j))
                txt = [txt sprintf('%6.0f', M(k, j))];
            else
                txt = [txt sprintf('%6.2f', M(k, j))];
            end

        end

        txt = [txt newline];
    end

end

%% lib\modecb.m
function modecb(arg, ~)

    if nargin == 0
        arg = findobj('callback', @modecb);
    end

    switch arg.String
        case 'rubik', mode = 'color';
        otherwise , mode = 'rubik';
    end

    arg.String = mode;
    qstate('mode', mode)
    Qshow(qstate('Q'))
    set(findobj('callback', @modecb), 'string', mode)
end

%% lib\nstrcb.m
function nstrcb(arg, ~)

    if nargin == 0
        arg = findobj('callback', @nstrcb);
    end

    n = str2double(arg.String);

    if isnan(n)
        n = 3;
    end

    if isequal(get(gcf, 'selectiontype'), 'alt')
        n = n + 1;
    else
        n = n - 1;
    end

    if n < 1
        n = 7;
    end

    nstr = num2str(n);
    arg.String = nstr;
    qstate('nstr', nstr)
    Q = Q0(nstr);
    qstate('Q', Q)
    Qshow(Q)
    initaxis(n)
end

%% lib\ops1.m
function ops1(arg, ~)
    arg.Value = 0;
    arg.String = '0';
end

%% lib\ops2.m
function ops2(arg, ~)
    arg.Value = 0;
    arg.String = '0';
end

%% lib\peek.m
function op = peek
    % peek   return top op
    stk = qstate('stack');
    tp = top(stk);
    op = stk(tp);
end

%% lib\pop.m
function op = pop
    % pop   remove op from top of stack
    stk = qstate('stack');
    tp = top(stk);
    op = stk(tp);
    stk(tp) = []; % delete top element
    show_stack(stk)
    qstate('stack', stk)
end

%% lib\prime.m
function op = prime(op)
    % op = op'
    if isempty(op)
        return
    elseif isscalar(op)
        op = [op char(' ' + '''' - op)];
    elseif op(2) ~= '2'
        op(2) = char(' ' + '''' - op(2));
    end

end

%% lib\push.m
function push(op, ~)
    % push  insert op on top of stack
    stk = qstate('stack');
    op(op == ' ') = [];
    op = [op ' '];
    lop = length(op);
    ops1 = findobj('callback', @ops1);
    metric = findobj('callback', @Qmetric);

    if isequal(metric(end).String, '1/2') && ...
            length(stk) >= lop && isequal(stk(end - lop + 1:end), op)
        stk = stk(1:end - lop);
        op = [op(1) '2 '];
        ops1.Value = ops1.Value - 1;
        ops1.String = num2str(ops1.Value);
    end

    stk = [stk op];
    show_stack(stk)
    qstate('stack', stk)
end

%% lib\pushbut.m
function pushbut(string, position, callback)
    uicontrol(Style = "pushbutton", ...
        String = string, ...
        Tag = string, ...
        Units = "normalized", ...
        Position = position, ...
        Callback = callback, ...
        Fontsize = qstate('font'), ...
        Fontweight = "bold", ...
        BackgroundColor = 'w');
end

%% lib\qstate.m
function vout = qstate(item, vin)
    % qstate(name,set_value)
    % get_value = qstate(name)

    items = {'Q', 'stack', 'stack2', 'speed', 'types', 'mode', 'nstr', ...
             'scram', 'font', 'gif', 'video'};
    nstr = '3';
    defaults = {Q0(nstr), '', '', 10, 0:7, 'color', nstr, '4', 24, [], []};

    state = get(gcf, 'userdata');

    if isempty(state)
        state = defaults;
        set(gcf, 'userdata', defaults)
    end

    for k = 1:length(items)

        if isequal(item, items{k})

            if nargin == 2
                state{k} = vin;
                set(gcf, 'userdata', state)
            else
                vout = state{k};
            end

            return
        end

    end

end

%% lib\qtrim1.m
function x = qtrim1(x)
    % X X'-> [].
    x = split(strip(x))';
    k = length(x) - 1;

    while k > 0

        if x(k) == erase((x(k + 1) + "'"), "''")
            x(k:k + 1) = [];
            k = k - 1;
        end

        k = k - 1;
    end

    x = join(x);
end

%% lib\qtrim2.m
function x = qtrim2(x)
    % X X -> X2
    x = split(strip(x))';
    k = length(x) - 1;

    while k > 0

        if x(k) == x(k + 1)
            x(k + 1) = [];
            x(k) = erase(x(k) + "2", "'");
        end

        k = k - 1;
    end

    x = join(x);
end

%% lib\quarter.m
function Qout = quarter(ax, f, sig, Q)

    if abs(sig) == 2
        Qout = quarter(ax, f, sig / 2, Q);
        Q = Qout;
        Qout = quarter(ax, f, sig / 2, Q);
    else
        Qout = Q;
        n = size(Q.V, 1);
        R = Rk(ax, sig * 90);

        switch ax
            case 'x'

                for j = 1:n

                    for k = 1:n

                        for i = f

                            if sig < 0
                                Qout.V{i, k, n + 1 - j} = Q.V{i, j, k} * R;
                                Qout.C{i, k, n + 1 - j} = Q.C{i, j, k};
                            else
                                Qout.V{i, n + 1 - k, j} = Q.V{i, j, k} * R;
                                Qout.C{i, n + 1 - k, j} = Q.C{i, j, k};
                            end

                        end

                    end

                end

            case 'y'

                for j = 1:n

                    for k = 1:n

                        for i = f

                            if sig < 0
                                Qout.V{j, i, n + 1 - k} = Q.V{k, i, j} * R;
                                Qout.C{j, i, n + 1 - k} = Q.C{k, i, j};
                            else
                                Qout.V{n + 1 - j, i, k} = Q.V{k, i, j} * R;
                                Qout.C{n + 1 - j, i, k} = Q.C{k, i, j};
                            end

                        end

                    end

                end

            case 'z'

                for j = 1:n

                    for k = 1:n

                        for i = f

                            if sig < 0
                                Qout.V{j, n + 1 - k, i} = Q.V{k, j, i} * R;
                                Qout.C{j, n + 1 - k, i} = Q.C{k, j, i};
                            else
                                Qout.V{n + 1 - j, k, i} = Q.V{k, j, i} * R;
                                Qout.C{n + 1 - j, k, i} = Q.C{k, j, i};
                            end

                        end

                    end

                end

        end

    end

end

%% lib\qzero.m
function q0 = qzero
    % Unit cubelet.
    q0 = [-1 -1 -1
          -1 -1 1
          -1 1 -1
          -1 1 1
          1 -1 -1
          1 -1 1
          1 1 -1
          1 1 1];
end

%% lib\randdo.m
function randdo(~, ~)
    op = random_op;
    Q = qstate('Q');
    Q = Qmove(op, Q);
    push(op)
    qstate('Q', Q)
end

%% lib\random_op.m
function op = random_op
    % alfa = 'LMRUEDFSBXYZ';
    alfa = 'LRUDFB';
    op = blanks(2);
    op(1) = alfa(randi(length(alfa)));

    if rand > 0.5
        op(2) = '''';
    end

end

%% lib\scramble.m
function scramble(arg, ~)

    if nargin == 0
        cnt = inf;
        arg = findobj('callback', @scramcb);
        arg.Value = 1;
    elseif nargin == 1
        cnt = str2double(arg.String);
        arg = findobj('callback', @scramble);
        arg.Value = 1;
    else
        scram = findobj('callback', @scramcb);

        if isequal(scram.String, 'scram')
            cnt = inf;
        else
            cnt = str2double(scram.String);
        end

    end

    v = arg.Value;
    arg.BackgroundColor = 1 - v * [.70 .25 .07];
    c = 0;

    while arg.Value > 0 && c < cnt
        randdo(arg)
        drawnow
        c = c + 1;
    end

    arg.Value = 0;
    arg.BackgroundColor = 'w';
end

%% lib\scramcb.m
function scramcb(arg, ~)
    % scram, number of random rotations.
    if nargin == 0
        arg = findobj('callback', @scramcb);
    end

    switch arg.String
        case 'inf', scram = '2';
        case '2', scram = '3';
        case '3', scram = '4';
        case '4', scram = '8';
        case '8', scram = '20';
        case '20', scram = 'inf';
        otherwise , scram = '3';
    end

    arg.String = scram;
    qstate('scram', str2double(scram))
    Qshow(qstate('Q'))
    set(findobj('callback', @scramcb), 'string', scram)
end

%% lib\show_stack.m
function show_stack(stk)
    stacker = findobj('callback', @stacker);
    %{
    if length(stk) > 72
        stk = [stk(1:18) ' ... ' stk(end-29:end)];
    end
    %}
    if ~isempty(stacker)
        stacker.String = stk;
    end

end

%% lib\speedcb.m
function speedcb(arg, ~)
    % speed, degrees  per fractional rotation.
    if nargin == 0
        arg = findobj('callback', @speedcb);
    end

    switch arg.String
        case '90', speed = '0';
        case '30', speed = '90';
        case '10', speed = '30';
        case '3', speed = '10';
        case '1', speed = '3';
        case '0', speed = '1';
        otherwise , speed = '10';
    end

    arg.String = speed;
    qstate('speed', str2double(speed))
    Qshow(qstate('Q'))
    set(findobj('callback', @speedcb), 'string', speed)
end

%% lib\stacker.m
function stacker(arg, ~)
    arg.String = '';
    qstate('stack', '')
end

%% lib\textbut.m
function textbut(string, position, tag)
    uicontrol(Style = "pushbutton", ...
        String = string, ...
        Units = "normalized", ...
        Position = position, ...
        Tag = tag, ...
        Fontsize = qstate('font'), ...
        Fontweight = "bold", ...
        BackgroundColor = 'w');
end

%% lib\toggbut.m
function toggbut(str, position, callback)
    v = isequal(str, ' ''');
    uicontrol(Style = "toggle", ...
        String = str, ...
        Units = "normalized", ...
        Position = position, ...
        Callback = callback, ...
        Value = v, ...
        Fontsize = qstate('font'), ...
        Fontweight = "bold", ...
        BackgroundColor = 'w');
end

%% lib\tooltips.m
function tooltips
    tip = @(x, y, z) set(findobj(x, y), 'tooltip', z);
    tip("string", "<=", "Apply inverse of most recent rotation.")
    tip("string", "<==", "Unscramble with repeated <='s.")
    tip("string", "=>", "One random rotation.")
    tip("string", "==>", "Scramble with scram =>'s.")
    tip("string", "n", "nxnxn cube.")
    tip("string", "speed", "Fractional rotation")
    tip("string", "types", "Center=0, face=1, edge=2, corner=3.")
    tip("string", "metric", "Quarter- or half-turn metric.")
    tip("string", "scram", "Number of =>'s in ==>.")
    tip("string", "solve", "Breadcrumbs algorithm.")
    tip("string", "order", "Number of repetitions to return to Q0.")
    tip("string", "Q0", "Initial configuration.")
    tip("string", "Q20", "Superflip.")
    tip("string", "Q26", "Superflip * fourscore.")
    tip("string", "viz", "Visibility of gui controls.")
    tip("string", "info", "help, blog.")
    tip("string", "apply", "Apply stack.")
    tip("string", "start", "Call Qube.")
    tip("string", "metric", "Quarter- or Half-Turn Metric.")
    tip("tag", "score", "Nuclear norm distance to Q0.")
    tip("tag", "fmat", "Rotations.")
    tip("callback", @modecb, "Rubik or Color Cube.")
    tip("callback", @ops1, "Total number of ops.")
    tip("callback", @ops2, "Number of order or solve ops.")
    tip("callback", @stacker, "Stack of ops, click to clear.")
    tip("callback", @fraccb, "Number of fractional steps in rotation.")
    tip("callback", @typescb, "Show center, face, edge, corner cubelets.")
end

%% lib\top.m
function top = top(s)
    % indices of first op in stack
    k = find((s ~= ' ') & (s ~= '''') & (s ~= '2'), 2, 'last');

    if length(k) > 1
        top = k(2):length(s);
    else
        top = 1:length(s);
    end

end

%% lib\types.m
function t = types(arg)
    % cubelet types
    s = qstate('types');
    t = (s(1) <= arg) && (arg <= s(end));
end

%% lib\typescb.m
function typescb(arg, ~)

    if nargin == 0
        arg = findobj('callback', @typescb);
    end

    switch arg.String
        case '2:3', s = '0:7';
        case '0:7', s = '0:5';
        case '0:5', s = '0:3';
        case '0:3', s = '0:2';
        case '0:2', s = '0:1';
        case '0:1', s = '0';
        case '0', s = '1';
        case '1', s = '2';
        case '2', s = '3';
        case '3', s = '4';
        case '4', s = '5';
        case '5', s = '2:3';
        otherwise , s = '0:7';
    end

    arg.String = s;
    qstate('types', str2double(s(1)):str2double(s(end)))
    Qshow
    n = str2double(qstate('nstr'));
    initaxis(n)
end

%% lib\unscramble.m
function unscramble(arg, ~)
    % undo.  bs until stack is empty.
    if nargin < 1
        arg = findobj('callback', @unscramble);
        arg.Value = 1;
    end

    while arg.Value > 0 && ~isempty(peek)
        bs(arg)
        drawnow
    end

    arg.BackgroundColor = 'w';
    arg.Value = 0;
end

%% lib\video_frame.m
function video_frame(~, ~)
    writeVideo(qstate('video'), getframe(gcf))
end

%% EOF
