# алгоритм поиска Q от ПАБ

function GetInterPoints(DataLine,LowThreshold,HighThreshold)
    # GetInterPoints - Search points on upgouig part of curve by two thresholds
    # DataLine - curve array
    # PLowPnt - last interpolated point where DataLine(PLowPnt) = LowThreshold 
    # PHighPnt - last interpolated point where DataLine(PHighPnt) = HighThreshold 
    #  Zero values return means not founded

    PLowPnt =0;
    PHighPnt = 0;
    HighPoint = 0;
    LowPoint = 0;
    MxDLPnt = 0;
    MxDLVal = 0;
    Dlen = lastindex(DataLine);
    for i = 1:Dlen #Search max point on DataLine - right limit for results
        Am = DataLine[i];
        if Am > MxDLVal
            MxDLVal = Am;
            MxDLPnt = i;
        end
    end
    for i = MxDLPnt:-1:1
        Am =DataLine[i];
        if Am < HighThreshold && HighPoint == 0
            HighPoint = i;
        end
        if Am < LowThreshold && LowPoint == 0
            LowPoint = i;
        end
    end
    if HighPoint > 0 && LowPoint > 0
        
        LowPoint = LowPoint + 1;
        PLowPnt = LowPoint - (DataLine[LowPoint] - LowThreshold)/(DataLine[LowPoint] - DataLine[LowPoint-1]);
        PHighPnt = HighPoint + (HighThreshold - DataLine[HighPoint])/(DataLine[HighPoint+1] - DataLine[HighPoint]);
        
    end
    return PLowPnt,PHighPnt
end
    

function CalcQSVectI(Freq,QSdata,isoline)
    # %UNTITLED2 Summary of this function goes here
    # % All values are normalised by pseudovector integral and scale 1000/50
    # %  Vamp - pseudovektor amplitude
    # %  Vdifamp - pseudovektor amplitude first difference  Difln
    # %  VdifTan - pseudovektor rotation - first difference
    # %  PdifAmp - промилле изменения амплитуды в изменении вектора
    # %  VampIntegralNorm - норм. интеграл амплитуды псевдовектора,промилле
    # %  
    # %  NrmVct - нормированные отведения
    # %  MxVcAmp - максимальная амплитуда псевдовектора
    # %  MVDA - максимальная первая разность амплитуды псевдовектора
    # %  MVDT - максимальный поворот псевдовектора
    # %   Detailed explanation goes here
    Nch = lastindex(QSdata); # number of channels
    Bflen = lastindex(QSdata[1]);# length of one channel buffer
    Isline = isoline; # length of isoline at buffer begining
    Difln = min(1, round(Int32, (4*Freq/1000))); # 1/2 length of differential window

    if Nch == 12 # Standard ECG - 8 independent channels
        Nch = 8;
        Chmsk = [1,2,7,8,9,10,11,12];
    else
        Chmsk = 1:Nch;
    end
    NrmVct = zeros(Nch,Bflen);
    Alpha = zeros(Bflen,1);
    for k=1:Nch # loop bu used channel - subtract isoline level, filling NrmVct
        Chind = Chmsk[k];
        IsLv = 0;
        for i=1:Isline #calculate isoline level for current channel
            IsLv = IsLv + QSdata[Chind][i];
        end
        IsLv = IsLv / Isline;
        for i=1:Bflen
            NrmVct[k,i] = QSdata[Chind][i]- IsLv;
        end
    end # NrmVct is formed, not normed
    # calculate MaxVectorAmp 

    MxVcAmp = 0;
    for i=1:Bflen
        VA = 0;
        for k=1:Nch
            VA = VA + NrmVct[k,i]*NrmVct[k,i];
        end
        if MxVcAmp < VA
            MxVcAmp = VA;
        end
    end
    MxVcAmp = sqrt(MxVcAmp);
    # Calculate VcAmp array
    VcAmp = zeros(Bflen, 1);
    for i=1:Bflen
        for k=1:Nch
            VcAmp[i] = VcAmp[i] + NrmVct[k,i]*NrmVct[k,i];
        end
        VcAmp[i] = sqrt(VcAmp[i]);
    end
    # Calculate VampInt array
    VampInt = zeros(Bflen, 1);
    VampIntCurr = 0;
    # NoiseLev = 5;
    # Integrate all from beg QRS to end QRS
    for i=isoline:Bflen
     #%   if VcAmp(i) >= NoiseLev
            VampIntCurr = VampIntCurr + VcAmp[i]/Freq;
    # %  end
        VampInt[i] = VampIntCurr;
    end
    VampIntCurr = VampIntCurr/1000;
    VampScale = 50;
    
    #  % norming all by VampIntCurr
    for i=1:Bflen
        VampInt[i] = VampInt[i] / VampIntCurr;
        VcAmp[i] = VcAmp[i]/VampIntCurr/VampScale;
        for k=1:Nch
            NrmVct[k,i] = NrmVct[k,i]/VampIntCurr/VampScale;
        end
        # расчет моментального угла альфа электрической оси сердца по амплитудам
        Alpha[i] = CalcAlphaECG(NrmVct[1,i],NrmVct[2,i]);
    end
    # % Calculate Alpa angle
    MxVcAmp = MxVcAmp / VampIntCurr/VampScale;
    # %Calculate VcDif array
    VcDifA = zeros(Bflen, 1);
    VcDifT = zeros(Bflen, 1);
    VcDifP = zeros(Bflen, 1);
    MVDA = 0;
    MVDT = 0;
    for i=Difln+1:Bflen-Difln-1
        for k=1:Nch
            DeltaVcK = NrmVct[k,i+Difln] - NrmVct[k,i-Difln];
            VcDifT[i] = VcDifT[i] + DeltaVcK*DeltaVcK;
        end
        VCD = sqrt(VcDifT[i]);
        VcDifA[i] = VcAmp[i+Difln]-VcAmp[i-Difln];
        VcDifT[i] = VcDifT[i] - VcDifA[i]*VcDifA[i];
        VcDifT[i] = sqrt(abs(VcDifT[i]));
        if VcDifA[i] > MVDA
            MVDA = VcDifA[i];
        end
        if VcDifT[i] > MVDT
            MVDT = VcDifT[i];
        end
        VcDifP[i] = abs(1000*VcDifA[i]/VCD); # доля изменения амплитуды в изменении вектора.
    end
    
    VampIntegralNorm =  VampInt;   
    Vamp = VcAmp;
    VdifAmp = VcDifA;
    VdifTan = VcDifT;
    PdifAmp = VcDifP;

    return Vamp,VdifAmp,VdifTan,PdifAmp,VampIntegralNorm,NrmVct,MxVcAmp,MVDA,MVDT,Alpha
end


function CalcAlphaECG(I,II)
    # % Расчет моментального угла альфа электрической оси сердца по амплитудам
    # % отведений I и II
    # %   Detailed explanation goes here
    # % Alpha = atan(II*sqrt(3)/(2*I+II)); % это в радианах
    if abs(I) < 0.001
        Alpha = 0;
        if II > 1
            Alpha = 90;
        elseif II < 1
            Alpha = -90;
        end
    else
        Alpha = 2*(II/I - 0.5)/sqrt(3); # это в радианах
        Alpha = atan(Alpha); # это в радианах
        Alpha = Alpha*180/3.1415926; # это в градусах
        if I < 0
            Alpha = 180 + Alpha;
        end
        if Alpha > 180
            Alpha = Alpha - 360;
        end
    end
    return Alpha
end


function  CalcInterpolAverage(Ldata,PlowP,PhighP)
    # Numeric integrate internal points
    Averval =0;
    Avlength = PhighP-PlowP;
    LowPoint = floor(Int32, PlowP+1);
    HighPoint = floor(Int32, PhighP);
    for i = LowPoint:HighPoint
        Averval = Averval + Ldata[i];
    end
    Averval = Averval -(Ldata[LowPoint] + Ldata[HighPoint])/2;
    # Add external points at low end
    C = LowPoint - PlowP;
    B = Ldata[LowPoint] - (C*(Ldata[LowPoint]- Ldata[LowPoint-1])/2);
    Averval = Averval + C*B;
    # Add external points at high end
    C = PhighP - HighPoint;
    B = Ldata[HighPoint] + (C*(Ldata[HighPoint+1]- Ldata[HighPoint])/2);
    Averval = Averval + C*B;
    # Divide by length - calc average level
    Averval = Averval / Avlength;
    return Averval
end
    