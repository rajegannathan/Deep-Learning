require("xlua")
require("image")
require("unsup")
require("convolutional_kmeans")

torch.manualSeed(1)
torch.setdefaulttensortype('torch.FloatTensor')
opt = {
   whiten = true,
}

local numSamples = 200
local numChannels = 3
local width = 96
local height = 96

local numPatches = 2
local kSize = 3 
local windowLength = numChannels*kSize*kSize
local windowFactor = 1

print("==> load dataset")
local trainData = {
   data = torch.Tensor(numSamples, numChannels * width * height),
   size = function() return numSamples end
}

trainData.data = torch.load('/home/ubuntu/extra.t7').data

--print(trainData.data:size())

local patches = torch.zeros(numPatches * kSize * kSize, windowLength)
for curSample = 1,numPatches do
    local r = torch.random(width - (windowFactor * kSize) + 1)
    local c = torch.random(height - (windowFactor * kSize) + 1)

    local sNo = math.fmod(curSample-1,numSamples)+1
    for i=r,r+kSize-1  do
      for j = c,c+kSize-1 do
        local patch = trainData.data[{sNo,{},{i,i+kSize-1},{j,j+kSize-1}}]
        local ptr = ((curSample - 1) * kSize * kSize) + ((i - r)*kSize) + (j-c) + 1
        --print("ptr is "..ptr .. " " .. curSample .. " " .. kSize .. " " .. i .. " " .. j)
        patches[{ptr,{}}] = patch:reshape(windowLength)
      end
    end
end

--print ("size of patches is ")
--print(patches:size())

local ncentroids = 4
local batchsize = math.min(torch.ceil(1000/(kSize*kSize)), patches:size(1))
kernels, counts = unsup.kmeans_convoluve(patches, ncentroids, nil, kSize, 0.1, 1, batchsize, nil, true)

print(kernels:size())
print(counts:size())

--torch.save('patches.t7', patches)
