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

%Centroid Matrix di sistem source (sistem 2)
Xm = sum(data(:,5),'all')/row;
Ym = sum(data(:,6),'all')/row;
Zm = sum(data(:,7),'all')/row;
% Matrix Koordinat Centroid
Mm = [
Xm;
Ym;
Zm;
];

% Pembuatan Matrix
% X = A * b (b matrix parameter)
% Definisi awal matrix X dan ukurannya
X = ones(row*3,1); % 3 is the X, Y and Z
A = zeros(row*3,7); % 7 is the total parameter

for i=1:row
    loop = 1;
    for j=i*3-2:i*3
        % Matrix Koordinat Sistem 1 (X)
        X(j,1) = data(i,loop+1) - data(i,loop+4); % + 1 karena row 2
        
        %Matrix Pengamatan (A)
        %Pengisian Kolom 1,2,3,5
        if loop==1
            A(j,1)=1; 
            A(j,5)=-1*(data(i,7)-Zm);
            A(j,6)=(data(i,6)-Ym);
        elseif loop==2
            A(j,2)=1;
            A(j,4)=(data(i,7)-Zm);
            A(j,6)=-1*(data(i,5)-Xm);
        elseif loop==3
            A(j,3)=1;
            A(j,4)=-1*(data(i,6)-Ym);
            A(j,5)=data(i,5)-Xm;
        end
        
        %Pengisian Kolom 7
        A(j,7) = data(i,loop+4) - Mm(loop,1);
        
        loop = loop+1;
    end    
end

% Perhitungan Matrix Parameter (b)
b = (A'*A)\(A'*X);

% Matriks V
v = A * b - X;

% Aposteriori
r = row*3 - 7; %Ukuran Lebih
So = (v'*v)/r;

% Matriks Variansi Kovariansi
Exx = So*inv(A'*A);

% Standar Deviasi
StdDev = sqrt(diag(Exx));

% Parameter Transformasi
Translasi = [
    b(1,1);
    b(2,1);
    b(3,1);
];
Skala = b(7,1);
Rx = b(4,1);
Ry = b(5,1);
Rz = b(6,1);
Rotasi = [
0 Rz -Ry;
-Rz 0 Rx;
Ry -Rx 0;
];

% Transformasi Koordinat dari Sistem Sumebr (sistem 2) ke sistem target
% (sistem 1)
DataOutput = [];
for i=1:size(dataTransformasi(:,1))
    coor = [
        dataTransformasi(i,2);
        dataTransformasi(i,3);
        dataTransformasi(i,4);
    ];
    Coor_sistemTarget = coor + Translasi + Rotasi * (coor - Mm) + (Skala) * (coor - Mm);

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
writetable(DataOutput,"Hasil_Transformasi_MolodenskyBadekas.xlsx");