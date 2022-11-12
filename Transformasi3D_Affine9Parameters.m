% ==========================================================
% Created by            : Fadillah Azhar Deaudin Kurniawan
% Email                 : fadillahazhardk@gmail.com
% github                : fadillahzahrdk
% Bandung, Indonesia 2022
% ==========================================================

clc
clear
format long g

% Import Data Common Point
% Kolom 2,3,4 : Sistem 1
% Kolom 5,6,7 : Sistem 2
% SCRIPT INI MENTRANSFORMASI DARI SISTEM 2 KE SISTEM 1
readData = readtable('Test_Data.xlsx', 'ReadVariableNames', true);
data = table2array(readData);

% Import Data Titik yang akan ditransformasi (sistem 2)
% Kolom 2,3,4 : Sistem 2
% Kolom 5,6,7 : True Coordinate Sistem 1 (Untuk Cek Perbedaan Hasil
% Transformasi)[OPSIONAL]
readData2 = readtable('Data_Sistem_Lokal.xlsx', 'ReadVariableNames', true);
dataTransformasi = table2array(readData2);
% Rubah jadi True jika terdapat data true coordinate
True_Coor_sistemTarget_Exist = true;

%Ukuran Data
sz = size(data);
%Jumlah Data
row = sz(1,1);

% Nilai Awal Parameter Rotasi dan Skala
S1=1; S2=1; S3=1; A1=0; A2=0; A3=0;
% Matrix Bobot (Default Nilainya = 1)
C1=eye(18,18); % Mesti Diubah dengan (banyak data X 3)
C=inv(C1);
% Nilai Awal Beda Parameter Rotasi dan Skala
del_S1=1; del_S2=1; del_S3=1; del_A1=1; del_A2=1; del_A3=1;

while (abs(del_S1)>1e-10)&&(abs(del_S2)>1e-10)&&(abs(del_S3)>1e-10)&&(abs(del_A1)>1e-10)&&(abs(del_A2)>1e-10)&&(abs(del_A3)>1e-10)
    % Inisiasi Matrix Pengamatan A dan Matrix Observasi L
    A=[];
    L=[];
    % Matrix Rotasi
    R=[
     cos(A2)*cos(A3), cos(A1)*sin(A3)+sin(A1)*sin(A2)*cos(A3), sin(A1)*sin(A3)- cos(A1)*sin(A2)*cos(A3);
    -cos(A2)*sin(A3), cos(A1)*cos(A3)-sin(A1)*sin(A2)*sin(A3), sin(A1)*cos(A3)+cos(A1)*sin(A2)*sin(A3);
    sin(A2), -sin(A1)*cos(A2), cos(A1)*cos(A2)
    ];
    % Elemen Matrix Rotasi
    r11o=R(1,1); r12o=R(1,2); r13o=R(1,3); 
    r21o=R(2,1); r22o=R(2,2); r23o=R(2,3);
    r31o=R(3,1); r32o=R(3,2); r33o=R(3,3);
    
    %Pembentukan Matrix Pengamatan dan Matrix Observasi
    for i=1:size(data(:,1))
        %Nilai Koordinat di Iterasi ke-1
        XS = data(i,5);
        YS = data(i,6);
        ZS = data(i,7);
        
        %Perhitungan Elemen Matrix Pengamatan
        a14 = r11o*XS;
        a15 = r12o*YS;
        a16 = r13o*ZS;
        a24 = r21o*XS; 
        a25 = r22o*YS;
        a26 = r23o*ZS;
        a34 = r31o*XS;
        a35 = r32o*YS;
        a36 = r33o*ZS;
        a17 = -S2*r13o*YS+S3*r12o*ZS;
        a27 = -S2*r23o*YS+S3*r22o*ZS;
        a37 = -S2*r33o*YS+S3*r32o*ZS;
        a18 = -cos(A3)*(S1*sin(A2)*XS+S2*r32o*YS+S3*r33o*ZS);
        a28 = sin(A3)*(S1*sin(A2)*XS+S2*r32o*YS+S3*r33o*ZS);
        a38 = S1*cos(A2)*XS+S2*sin(A1)*sin(A2)*YS-S3*cos(A1)*sin(A2)*ZS;
        a19 = S1*r21o*XS+S2*r22o*YS+S3*r23o*ZS;
        a29 = -(S1*r11o*XS+S2*r12o*YS+S3*r13o*ZS);
        a39 = 0;
        
        % Matrix Pengamatan untuk Koordinat ke-i
        Ai =[
        1 0 0 a14 a15 a16 a17 a18 a19;
        0 1 0 a24 a25 a26 a27 a28 a29;
        0 0 1 a34 a35 a36 a37 a38 a39;
        ]; 
    
        % Penambahan Matrix Pengamatan koordinat ke-1 ke Matrix Pengamatan
        % Total
        A=[A;Ai];
        
        % Perhitungan Matrix Observasi Koordinat ke-1
        L1=(data(i,2)-(S1*r11o*XS+S2*r12o*YS+S3*r13o*ZS));
        L2=(data(i,3)-(S1*r21o*XS+S2*r22o*YS+S3*r23o*ZS));
        L3=(data(i,4)-(S1*r31o*XS+S2*r32o*YS+S3*r33o*ZS));
        Li=[L1;L2;L3]; 
        
        % Penambahan Matrix Observasi koordinat ke-1 ke Matrix Pengamatan
        % Total
        L=[L;Li];
    end
    
    % Perhitungan Matrix Parameter (b)
    b = inv(A'*C*A)*A'*C*L; % Estimasi 9 Parameter
    del_S1 = b(4);
    del_S2 = b(5);
    del_S3 = b(6);
    del_A1 = b(7);
    del_A2 = b(8);
    del_A3 = b(9);
    S1= S1+del_S1;
    S2= S2+del_S2;
    S3= S3+del_S3;
    A1=A1+del_A1;
    A2= A2+del_A2;
    A3= A3+del_A3;
end

% Matriks V (Residu)
v=L-A*b; 

% Aposteriori
r = row*3 - 9; %Ukuran Lebih
So = (v'*v)/r;

% Matriks Variansi Kovariansi
Exx = So*inv(A'*A);

% Standar Deviasi
StdDev = sqrt(diag(Exx));

%Parameter Transformasi
Translasi = [
b(1,1);
b(2,1);
b(3,1)
];
Skala = [
    S1 0 0;
    0 S2 0;
    0 0 S3
];
Rotasi = R;

% Transformasi Koordinat dari Sistem Sumebr (sistem 2) ke sistem target
% (sistem 1)
DataOutput = [];
for i=1:size(dataTransformasi(:,1))
    coor = [
        dataTransformasi(i,2);
        dataTransformasi(i,3);
        dataTransformasi(i,4);
    ];
    Coor_sistemTarget = Translasi + Skala * Rotasi * coor;

    % Jika Data Terdapat True Coordinate Target
    if True_Coor_sistemTarget_Exist == true
        True_Coor_sistemTarget = [
            dataTransformasi(i,5);
            dataTransformasi(i,6);
            dataTransformasi(i,7);
        ];
        Perbedaan_Hasil = True_Coor_sistemTarget - Coor_sistemTarget;
        
        DataOutput = [
            DataOutput;
            i dataTransformasi(i,2) dataTransformasi(i,3) dataTransformasi(i,4) Coor_sistemTarget(1,1) Coor_sistemTarget(2,1) Coor_sistemTarget(3,1) Perbedaan_Hasil(1,1) Perbedaan_Hasil(2,1) Perbedaan_Hasil(3,1);
        ];
    else
        DataOutput = [
            DataOutput;
            i dataTransformasi(i,2) dataTransformasi(i,3) dataTransformasi(i,4) Coor_sistemTarget(1,1) Coor_sistemTarget(2,1) Coor_sistemTarget(3,1);
        ];
    end
end

%Tabel Hasil Transformasi
DataOutput = array2table(DataOutput);
if True_Coor_sistemTarget_Exist == true
    DataOutput.Properties.VariableNames = ["Titik", "X_2", "Y_2", "Z_2", "X_1", "Y_1", "Z_1", "Perbedaan X (m)", "Perbedaan Y (m)", "Perbedaan Z (m)"]
else
    DataOutput.Properties.VariableNames = ["Titik", "X_2", "Y_2", "Z_2", "X_1", "Y_1", "Z_1"]
end
%Export Hasil Transformasi ke file Excel
writetable(DataOutput,"Hasil_Transformasi_Affine9Parameter.xlsx");