clc
clear
format long g

% Import Data Common Point
readData = readtable('Transformasi_New.xlsx', 'ReadVariableNames', true);
data = table2array(readData);
%Ukuran Data
sz = size(data);
%Jumlah Data
row = sz(1,1);

% Import Data Titik yang akan ditransformasi (sistem 2)
% Kolom 2,3,4 : Sistem 2
% Kolom 5,6,7 : True Coordinate Sistem 1 (Untuk Cek Perbedaan Hasil
% Transformasi)[OPSIONAL]
readData2 = readtable('Transformated.xlsx', 'ReadVariableNames', true);
dataTransformasi = table2array(readData2);
% Rubah jadi True jika terdapat data true coordinate
True_Coor_sistemTarget_Exist = false;

% Pembuatan Matrix
% X = A * b (b matrix parameter)
% Predifined X matrix and its size
X = ones(row*2,1); % 2 is the X and Y
% Predifined A matrix and its size (Matrix Pengamatan)
A = ones(row*2,4); % 4 is the total parameter

for i=1:row
    loop = 1;
    for j=i*2-1:2*i
        % Matrix Koordinat Sistem 1 (X)
        X(j,1) = data(i,loop+1); % + 1 karena row 2
        
        %Matrix Pengamatan (A)
        %Pengisian Kolom 1
        A(j,1) = data(i,loop+4); % + 4 karena row 4
        %Pengisian Kolom 2
        A(j,2) = data(i,7-loop); % 7 - loop karena ingin mengambil kolom 6 dan 5
        if loop==2
            A(j,2) = A(j,2) * -1;
            %Pengisian Kolom 3
            A(j,3) = 0;
        elseif loop==1
            %Pengisian Kolom 4
            A(j,4) = 0;
        end
        
        loop = 2;
    end
end

% Perhitungan Matrix Parameter (b)
b = (A'*A)\(A'*X);

% Matriks V
v = A * b - X;

% Aposteriori
r = row*2 - 4; %Ukuran Lebih
So = (v'*v)/r;

% Matriks Variansi Kovariansi
Exx = So*inv(A'*A);

% Standar Deviasi Parameter
Std = sqrt(diag(Exx));

% Parameter Transformasi Sistem 2 Ke 1
Teta = atan(b(2,1));
Skala = sqrt(b(1,1)^2+b(2,1)^2);
Tx = b(3,1);
Ty = b(4,1);
R = [
cos(Teta) sin(Teta);
-sin(Teta) cos(Teta)
];

% Transformasi Koordinat dari Sistem Sumebr (sistem 2) ke sistem target
% (sistem 1)
DataOutput = [];
for i=1:size(dataTransformasi(:,1))
    coor = [
        dataTransformasi(i,2);
        dataTransformasi(i,3);
    ];
    Coor_sistemTarget = Skala * R * coor + [Tx;Ty];

    % Jika Data Terdapat True Coordinate Target
    if True_Coor_sistemTarget_Exist == true
        True_Coor_sistemTarget = [
            dataTransformasi(i,5);
            dataTransformasi(i,6);
        ];
        Perbedaan_Hasil = True_Coor_sistemTarget - Coor_sistemTarget;
        
        DataOutput = [
            DataOutput;
            i dataTransformasi(i,2) dataTransformasi(i,3) dataTransformasi(i,4) Coor_sistemTarget(1,1) Coor_sistemTarget(2,1) Coor_sistemTarget(3,1) Perbedaan_Hasil(1,1) Perbedaan_Hasil(2,1) Perbedaan_Hasil(3,1);
        ];
    else
        DataOutput = [
            DataOutput;
            i dataTransformasi(i,2) dataTransformasi(i,3) Coor_sistemTarget(1,1) Coor_sistemTarget(2,1);
        ];
    end
end

%Tabel Hasil Transformasi
DataOutput = array2table(DataOutput);
if True_Coor_sistemTarget_Exist == true
    DataOutput.Properties.VariableNames = ["Titik", "X_2", "Y_2", "Z_2", "X_1", "Y_1", "Perbedaan X (m)", "Perbedaan Y (m)"]
else
    DataOutput.Properties.VariableNames = ["Titik", "X_2", "Y_2", "X_1", "Y_1"]
end
%Export Hasil Transformasi ke file Excel
writetable(DataOutput,"Hasil_Transformasi_2D.xlsx");

% % Testing Parameter Sistem 2 ke 1
% R = [
% cos(Teta) sin(Teta);
% -sin(Teta) cos(Teta)
% ];
% Sistem2 = [
% 544917.159;
% 220671.739
% ];
% Sistem1 = Skala * R * Sistem2 + [Tx;Ty];
% 
% % Uji Global
% cSVar = r * So;
% 
% % Uji Lokal
% t = ones(row*2,1);
% Qvv = A * inv(A'*A) * A';
% diagQvv = diag(Qvv);
% for i=1:row*2
%     t(i,1) = v(i,1) / diagQvv(i,1);
% end