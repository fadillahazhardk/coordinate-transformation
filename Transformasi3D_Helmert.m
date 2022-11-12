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
S1=1; A1=0; A2=0; A3=0;
% Matrix Bobot (Default Nilainya = 1)
C1=eye(18,18); % Mesti Diubah dengan (banyak data X 3)
C=inv(C1);
% Nilai Awal Beda Parameter Rotasi dan Skala
del_S=1; del_A1=1; del_A2=1; del_A3=1;

while (abs(del_S)>1e-10)&&(abs(del_A1)>1e-10)&&(abs(del_A2)>1e-10)&&(abs(del_A3)>1e-10)
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
        %Perhitungan Elemen Matrix Pengamatan
        a14=(r11o*data(i,5)+r12o* data(i,6)+r13o*data(i,7));
        a24=(r21o*data(i,5)+r22o* data(i,6)+r23o*data(i,7));
        a34=(r31o*data(i,5)+r32o*data(i,6)+r33o*data(i,7));
        a15=(S1*(-r13o*data(i,6)+r12o*data(i,7)));
        a25=(S1*(-r23o*data(i,6)+r22o*data(i,7)));
        a35=(S1*(-r33o*data(i,6)+r32o*data(i,7)));
        a16= -S1*cos(A3)*(sin(A2)*data(i,5)+r32o*data(i,6)+r33o*data(i,7));
        a26= S1*sin(A3)*(sin(A2)*data(i,5)+r32o*data(i,6)+r33o*data(i,7));
        a36= S1*(cos(A2)*data(i,5)+sin(A1)*sin(A2)*data(i,6)-cos(A1)*sin(A2)*data(i,7));
        a17=(S1*(r21o*data(i,5)+r22o*data(i,6)+r23o*data(i,7)));
        a27=(-S1*(r11o*data(i,5)+r12o*data(i,6)+r13o*data(i,7)));
        a37=0;
        
        % Matrix Pengamatan untuk Koordinat ke-i
        Ai =[1, 0, 0, a14, a15, a16, a17;
        0, 1, 0, a24, a25, a26, a27;
        0, 0, 1, a34, a35, a36, a37;]; 
    
        % Penambahan Matrix Pengamatan koordinat ke-1 ke Matrix Pengamatan
        % Total
        A=[A;Ai];
        
        % Perhitungan Matrix Observasi Koordinat ke-1
        L1=(data(i,2)-S1*(r11o*data(i,5)+r12o*data(i,6)+r13o*data(i,7)));
        L2=(data(i,3)-S1*(r21o*data(i,5)+r22o*data(i,6)+r23o*data(i,7)));
        L3=(data(i,4)-S1*(r31o*data(i,5)+r32o*data(i,6)+r33o*data(i,7)));
        
        % Penambahan Matrix Observasi koordinat ke-1 ke Matrix Pengamatan
        % Total
        Li=[L1;L2;L3]; L=[L;Li];
    end
    % Perhitungan Matrix Parameter (b)
    b = inv(A'*C*A)*A'*C*L; % Estimasi 7 Parameter
    del_S = b(4);
    del_A1 = b(5);
    del_A2 = b(6);
    del_A3 = b(7);
    S1= S1+del_S;
    A1=A1+del_A1;
    A2= A2+del_A2;
    A3= A3+del_A3;
end

% Matriks V (Residu)
v=L-A*b; 

% Aposteriori
r = row*3 - 7; %Ukuran Lebih
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
Skala = S1;
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
writetable(DataOutput,"Hasil_Transformasi_Helmert3D.xlsx");