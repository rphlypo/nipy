itype=1;
types=['_evt '; '_bloc'; '_comb'];
type=deblank(types(itype,:))
subjs=[0 1 3 4 6 7 8 9 10 11 12 13 14 15];
switch itype
case 1
   runs=[3 4; 3 4; 3 4; 1 2; 1 4; 1 0; 1 4; 4 0; 2 4; 2 4; 2 4; 2 3; 2 3; 2 3; 1 3; 1 3];
case 2
   runs=[1 2; 1 2; 1 2; 3 4; 2 3; 2 0; 2 3; 2 3; 1 3; 1 3; 1 3; 1 4; 1 4; 1 4; 2 4; 2 4];
case 3
   runs=[[3 4; 3 4; 3 4; 1 2; 1 4; 1 0; 1 4; 4 0; 2 4; 2 4; 2 4; 2 3; 2 3; 2 3; 1 3; 1 3] ...
         [1 2; 1 2; 1 2; 3 4; 2 3; 2 0; 2 3; 2 3; 1 3; 1 3; 1 3; 1 4; 1 4; 1 4; 2 4; 2 4]];
end
nsubjs=length(subjs)

slicetimes=zeros(1,30)+1.25;
frametimes=(0:190)*2.5;
contrast=[0.25 0.25 0.25 0.25;
          -0.5 -0.5 0.5 0.5;
          -0.5 0.5 -0.5 0.5;
          1 -1 -1 1];
exclude=[];
which_stats='_mag_t _mag_sd _mag_ef _del_t _del_sd _del_ef _cor';

for isubj=1:nsubjs
   subj=subjs(isubj)
   for irun=1:4
      run=runs(subj+1,irun)
      if run>0
         evt=load(['c:/keith/fMRI/contest/fiac' num2str(subj) ...
               '/subj' num2str(subj) type '_fonc' num2str(run) '.txt']);
         nevt=size(evt,1);
         events=[evt(:,2) evt(:,1) zeros(nevt,1), ones(nevt,1)];
         if itype==1
            events(1,1)=5;
         else
            events((0:15)*6+1,1)=5;
         end
         X_cache=fmridesign(frametimes,slicetimes,events);
         input_file=['c:/FIAC/fiac' num2str(subj) '/fsl' num2str(run) '/filtered_func_data.img'];
         base=['c:/keith/fMRI/contest/fiac' num2str(subj) ...
               '/fiac' num2str(subj) '_fonc' num2str(run)];
         output_file_base=[ [base '_all']; [base '_sen']; [base '_spk']; [base '_snp'] ];
         fmrilm(input_file, output_file_base, X_cache, contrast, exclude, which_stats);
      end
   end
end

% clf; view_slices([output_file_base(2,:) '_mag_t.img'])
% clf; view_slices(input_file,[],[],0:29,1)

Xe=X_cache.X(:,:,1,1);
Xb=X_cache.X(:,:,1,1);
subplot(3,1,1)
plot(frametimes,Xe); ylim([-0.2 0.5])
subplot(3,1,3)
plot(frametimes,Xb); ylim([-0.2 0.5]); xlabel('Seconds')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

md=['_mag'; '_del'];
contr=['_all'; '_sen'; '_spk'; '_snp'];
stat=['_ef'; '_sd'];
standard='c:/cygwin/usr/local/fsl/etc/standard/avg152T1_brain.img';
d2=fmris_read_image(standard)
[x,y,z]=ndgrid(0:(d2.dim(1)-1),(d2.dim(2)-1):-1:0,0:(d2.dim(3)-1));
standard_thresh=fmri_mask_thresh(standard)
clf; view_slices(standard)
d3=fmris_read_image(standard);
d3.data=Inf;
nmd=2;
if itype==3
   nmd=1;
end
   
for isubj=1:nsubjs
   subj=subjs(isubj)
   
   for irun=1:size(runs,2)
      run=runs(subj+1,irun);
      if run>0
         base=['c:/keith/fMRI/contest/fiac' num2str(subj) ...
               '/fiac' num2str(subj) '_fonc' num2str(run)];
         xfm=['c:/FIAC/fiac' num2str(subj) '/fsl' num2str(run) '/example_func2standard.xfm'];
         fid=fopen(xfm);
         m=fscanf(fid,'%s',6);
         m=fscanf(fid,'%f',[4,4])';
         fclose(fid);
         R=inv(m);
         Rx=R(1,1)*x+R(1,2)*y+R(1,3)*z+R(1,4)+1;
         Ry=64-(R(2,1)*x+R(2,2)*y+R(2,3)*z+R(2,4));
         Rz=R(3,1)*x+R(3,2)*y+R(3,3)*z+R(3,4)+1;
         for icontr=1:4
            for imd=1:nmd
               for istat=1:2
                  input_file=[base contr(icontr,:) md(imd,:) stat(istat,:) '.img'];
                  d1=fmris_read_image(input_file);
                  d2.data=interpn(d1.data,Rx,Ry,Rz);
                  d2.data(find(isnan(d2.data)))=0;
                  d2.df=d1.df;
                  d2.fwhm=d1.fwhm;
                  d2.file_name=['c:/keith/fMRI/contest/test/test_run' ...
                        num2str(irun) contr(icontr,:) md(imd,:) stat(istat,:) '.img'];
                  d2.parent_file=standard;
                  fmris_write_image(d2,1:d2.dim(3),1);
                  % clf; view_slices(d2.file_name,standard,-1,0:79,1,[-6 18])
               end
            end
         end
         input_file=['c:/FIAC/fiac' num2str(subj) '/fsl' num2str(run) '/filtered_func_data.img'];
         d1=fmris_read_image(input_file,1:30,1);
         d2.data=interpn(d1.data,Rx,Ry,Rz);
         d2.data(find(isnan(d2.data)))=0;
         d3.data=min(d2.data,d3.data);
      end
   end
   
   for icontr=1:4
      for imd=1:nmd
         if sum(runs(subj+1,:)>0)>1
            input_files_ef=[];
            input_files_sd=[];
            for irun=1:size(runs,2)
               run=runs(subj+1,irun);
               if run>0
                  input_files_ef=[input_files_ef; ['c:/keith/fMRI/contest/test/test_run' ...
                           num2str(irun) contr(icontr,:) md(imd,:) stat(1,:) '.img']];
                  input_files_sd=[input_files_sd; ['c:/keith/fMRI/contest/test/test_run' ...
                           num2str(irun) contr(icontr,:) md(imd,:) stat(2,:) '.img']];
               end
            end
            output_file_base=['c:/keith/fMRI/contest/subj/subj' num2str(subj) ...
                  type contr(icontr,:) md(imd,:)];
            which_stats='_ef _sd _t';
            multistat(input_files_ef,input_files_sd,[],[],[],1,output_file_base,which_stats,Inf);
         else
            d1=fmris_read_image(['c:/keith/fMRI/contest/test/test_run1' ...
                     contr(icontr,:) md(imd,:) '_ef.img']);
            d1.file_name=['c:/keith/fMRI/contest/subj/subj' num2str(subj) ...
                     type contr(icontr,:) md(imd,:) '_ef.img'];
            fmris_write_image(d1);
            d2=fmris_read_image(['c:/keith/fMRI/contest/test/test_run1' ...
                     contr(icontr,:) md(imd,:) '_sd.img']);
            d2.file_name=['c:/keith/fMRI/contest/subj/subj' num2str(subj) ...
                     type contr(icontr,:) md(imd,:) '_sd.img'];
            fmris_write_image(d2);
            d1.data=d1.data./(d2.data+(d2.data<=0)).*(d2.data>0);
            d1.df=d2.df;
            d1.file_name=['c:/keith/fMRI/contest/subj/subj' num2str(subj) ...
                     type contr(icontr,:) md(imd,:) '_t.img'];
            fmris_write_image(d1);
         end
      end
   end
end

min_fmri=['c:/keith/fMRI/contest/subj/mask' type '.img']
d3.file_name=min_fmri;
d3.parent_file=standard;
fmris_write_image(d3,1:d3.dim(3),1);

%%%%%%%%%%%%%%%%%%%%%%%%

for icontr=1:4
   for imd=1:nmd
      input_files_ef=[];
      input_files_sd=[];
      for isubj=1:nsubjs
         subj=subjs(isubj);
         if subj>=10
            blank=[];
         else
            blank=' ';
         end
         output_file_base=['c:/keith/fMRI/contest/subj/subj' num2str(subj) ...
               type contr(icontr,:) md(imd,:) ];
         input_files_ef=[input_files_ef; [output_file_base '_ef.img' blank]];
         input_files_sd=[input_files_sd; [output_file_base '_sd.img' blank]];
      end
      output_file_base=['c:/keith/fMRI/contest/multi/multi' type contr(icontr,:) md(imd,:)];
      which_stats='_ef _sd _t _fwhm _rfx';
      multistat(input_files_ef,input_files_sd,[],[],ones(nsubjs,1),1,output_file_base,which_stats);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%

clf;
view_slices(min_fmri)
min_thresh=fmri_mask_thresh(min_fmri)
mask_vol(min_fmri,min_thresh)
clf;
view_slices(min_fmri,min_fmri,min_thresh)
d=fmris_read_image(min_fmri);
min_thresh/max(d.data(:))
     0.3450 block 
     0.3650 event
     0.3750 combo
     
mask_file=['c:/keith/fMRI/contest/multi/multi' type '_all_mag_t.img'];
clf; view_slices(mask_file,min_fmri,min_thresh,0:90,1,[5 10])
clf; view_slices(mask_file,min_fmri,min_thresh,35,1,[5 10])

mask_del_file=['c:/keith/fMRI/contest/multi/mask' type '_del_file.img'];
math_vol(mask_file,min_fmri,['b=min(a{1}/5,a{2}/' num2str(min_thresh) ');'],mask_del_file);
clf; view_slices(mask_del_file)

for imd=1:nmd
   for icontr=1:4
      if imd==1
         mask_file=min_fmri;
         mask_thresh=min_thresh;
         input_thresh=0.001;
      else
         mask_file=mask_del_file;
         mask_thresh=1;
         input_thresh=0.01;
      end
      output_file_base=['c:/keith/fMRI/contest/multi/multi' type contr(icontr,:) md(imd,:)]
      stats_file_base=['c:/keith/fMRI/contest/stats/multi' type contr(icontr,:) md(imd,:)]
      for iflip=1:2
         diary([stats_file_base '_flip' num2str(iflip) '.txt'])
         stat_summary([output_file_base '_t.img'], ...
            [output_file_base '_fwhm.img'],[],mask_file,mask_thresh,input_thresh,3-iflip*2);
         diary('off')
         saveas(gcf,[stats_file_base '_flip' num2str(iflip) '.eps'],'epsc2');
      end
   end
end

clf;
view_slices(mask_file)
clf;
view_slices(input_files_sd,[],[],0:90,1,[0 0.01])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sqrt(diag(m*m')*ones(1,size(m,1))+(diag(m*m')*ones(1,size(m,1)))'-2*m*m')<8.6


for imd=1:2
   if imd==1
      mask_file=min_fmri;
      mask_thresh=min_thresh;
      slices=[8:73];
   else
      mask_file=['c:/keith/fMRI/contest/multi/multi' type '_all_mag_t.img'];
      mask_thresh=5;
      slices=27:43;
   end
   for icontr=1:4
      output_file_base=['c:/keith/fMRI/contest/multi/multi' type contr(icontr,:) md(imd,:)]
      figure(1); clf; view_slices([output_file_base '_ef.img'],mask_file,mask_thresh,slices)
      figure(2); clf; view_slices([output_file_base '_sd.img'],mask_file,mask_thresh,slices)
      figure(3); clf; view_slices([output_file_base '_t.img'],mask_file,mask_thresh,slices)
      figure(4); clf; view_slices([output_file_base '_rfx.img'],mask_file,mask_thresh,slices)
      figure(5); clf; view_slices([output_file_base '_fwhm.img'],mask_file,mask_thresh,slices)
      pause
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

s=load('c:/keith/papers/fiac/table2.txt')
for imd=1:2
   for icontr=2:4
      for itype=1:3
         for isign=1:-2:-1
            ind=find(s(:,1)==imd & s(:,2)==icontr & s(:,3)==itype & sign(s(:,5))==isign);
            if ~isempty(ind)
               m=s(ind,1:12);
               [imd icontr itype isign]
               sqrt(diag(m*m')*ones(1,size(m,1))+(diag(m*m')*ones(1,size(m,1)))'-2*m*m')<8.6
            end
         end
      end
   end
end

efs=zeros(size(s,1),1);
sds=zeros(size(s,1),1);
for i=1:size(s,1)
   vox=s(i,7:9);
   efs(i)=extract(vox,['c:/keith/fMRI/contest/multi/multi' ...
         deblank(types(s(i,3),:)) contr(s(i,2),:) md(s(i,1),:) '_ef.img']);
   sds(i)=extract(vox,['c:/keith/fMRI/contest/multi/multi' ...
         deblank(types(s(i,3),:)) contr(s(i,2),:) md(s(i,1),:) '_sd.img']);
end
num2str(round([efs./sds efs sds ]*1000)/1000)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% whitebg

thresholds=zeros(4,2,3)
thresholds(2,1,1)=5.68;
thresholds(2,1,2)=5.67;
thresholds(2,2,1)=4.31;
thresholds(2,2,2)=4.30;

slice=36;
d=fmris_read_image(['c:/keith/fMRI/contest/multi/multi' type '_all_mag_t.img'],slice,1);
[x,y]=ind2sub(d.dim(1:2),find(d.data>5));
xr=(min(x)-1):(max(x)+1);
yr=(min(y)-1):(max(y)+1);
xr=9:81;
yr=41:66;
nx=length(xr)
ny=length(yr)
stats=['_ef  '; '_sd  '; '_t   '];
labelcontr=[
   'stimulus average    '; 
   'diff - same sentence'; 
   'diff - same speaker '; 
   'interaction         '];
labelmd=['Magnitude (%BOLD) ';
         'Delay shift (secs)']
labelmask=['Contour is: min fMRI >                                ';
           'Contour is: magnitude, stimulus average, T statistic >']; 
labeltype=['event'; 'block'];
zcoord=(slice-d.origin(3))*d.vox(3)
nstats=size(stats,1)

for itype=1:2
type=deblank(types(itype,:))
min_fmri=['c:/keith/fMRI/contest/subj/mask' type '.img']
min_thresh=fmri_mask_thresh(min_fmri)
m=zeros(nx,(ny+1)*nsubjs-1,nstats)*nan;
m2=zeros(nx,ny,nstats);
dfs=zeros(1,nsubjs);
for imd=1:2
   masks=zeros(nx,(ny+1)*nsubjs-1);
   for isubj=1:nsubjs
      subj=subjs(isubj);
      if imd==1
         mask_file=min_fmri;
      else
         mask_file=['c:/keith/fMRI/contest/subj/subj' num2str(subj) ...
               type '_all_mag_t.img'];
      end
      d=fmris_read_image(mask_file,slice,1);
      masks(:,(1:ny)+(isubj-1)*(ny+1))=d.data(xr,yr);
   end
   if imd==1
      mask_file=min_fmri;
      mask_thresh=min_thresh;
   else
      mask_file=['c:/keith/fMRI/contest/multi/multi' type '_all_mag_t.img'];
      mask_thresh=5;
   end
   d=fmris_read_image(mask_file,slice,1);
   mask=d.data(xr,yr);
   for icontr=2
      for isubj=1:nsubjs
         subj=subjs(isubj);
         output_file_base=['c:/keith/fMRI/contest/subj/subj' num2str(subj) ...
               type contr(icontr,:) md(imd,:) ];
         for istat=1:nstats
            d=fmris_read_image([output_file_base deblank(stats(istat,:)) '.img'],slice,1);
            m(:,(1:ny)+(isubj-1)*(ny+1),istat)=d.data(xr,yr);
         end
         dfs(isubj)=d.df;
      end
      output_file_base=['c:/keith/fMRI/contest/multi/multi' type contr(icontr,:) md(imd,:)];
      for istat=1:nstats
         d=fmris_read_image([output_file_base deblank(stats(istat,:)) '.img'],slice,1);
         m2(:,:,istat)=d.data(xr,yr);
      end
      df=d.df;
      d=fmris_read_image([output_file_base '_rfx.img'],slice,1);
      m3=d.data(xr,yr);
      fwhm_varatio=d.fwhm(2);
      d=fmris_read_image([output_file_base '_fwhm.img'],slice,1);
      m4=d.data(xr,yr);
      if itype==1
         if icontr==1
            zlim=[-2 7; 0 2; -5 8];
            sdratiolim=[0.5 1.5];
         else
            zlim=[-2 2; 0 1; -5 5];
            sdratiolim=[0.5 1.5];
         end
         if imd==2
            zlim=[-0.3 0.3; 0 0.6; -3 3];
            sdratiolim=[0.5 1.5];
         end
      else
         if icontr==1
            zlim=[-1 5; 0 1; -5 20];
            sdratiolim=[0.5 7.5];
         else
            zlim=[-2 2; 0 1; -5 5];
            sdratiolim=[0.5 1.5];
         end
         if imd==2
            zlim=[-1 1; 0 2; -3 3];
            sdratiolim=[0.5 1.5];
         end
      end
      clf; colormap(spectral);
      for istat=1:nstats
         axes('position',[0.05 1-istat*0.3 0.7 0.2])
         imagesc(m(:,:,istat),zlim(istat,:)); axis off;
         hold on; contour(masks,[mask_thresh mask_thresh],'k');hold off;
         axes('position',[0.77 1-istat*0.3 0.7/nsubjs*1.14 0.2])
         imagesc(m2(:,:,istat),zlim(istat,:)); 
         h=colorbar; pp=get(h,'Position'); set(h,'Position',[pp(1:2) pp(4)/12 pp(4)]); 
         axis off;
         hold on; contour(mask,[mask_thresh mask_thresh],'k');hold off;
      end
      text(-5,-215,repmat('Left                Right                ',1,3),'Rotation',270)
      text(0,75,'Post.','Rotation',270)
      text(30,75,'Ant.','Rotation',270)
      for isubj=1:nsubjs
         subj=subjs(isubj);
         text(-(nsubjs-isubj)*(ny+0.5)-ny-5,-225,num2str(subj));
         text(-(nsubjs-isubj)*(ny+0.5)-ny-5,-20,num2str(dfs(isubj)));
      end
      text(10,-20,num2str(df));
      text(-400,-225,'Subj')
      text(0,-230,[' Mixed '; 'effects'])
      text(-400,-180,'Ef')
      text(-400,-75,'Sd')
      text(-400,+35,'T')
      text(-400,-20,'df')
      text(-400,-240,[deblank(labelmd(imd,:)) ', ' deblank(labelcontr(icontr,:)) ...
            ', '  deblank(labeltype(itype,:))  ' experiment'])
      text(-400,-130,['Slice range is ' ...
         num2str((min(xr)-d.origin(1))*2) '<x<' num2str((max(xr)-d.origin(1))*2) 'mm, ' ...
         num2str((min(yr)-d.origin(2))*2) '<y<' num2str((max(yr)-d.origin(2))*2) 'mm, ' ...
         ' z=' num2str(zcoord) 'mm; ' ...
         deblank(labelmask(imd,:)) ' ' num2str(round(mask_thresh))]); 
      text(70,-145,['Random    ';  '/fixed    '; 'effects sd'; 'smoothed  '])
      text(70,-120,[num2str(fwhm_varatio) 'mm'])
      text(70,-10,'FWHM (mm)')
      t=thresholds(icontr,imd,itype);
      if t>0; 
         text(-200,85,['P=0.05 threshold for local maxima is +/- ' num2str(t)]); 
      else
         text(-200,85,'Local maxima not significant at P=0.05');
      end
      axes('position',[0.90 1-2*0.3 0.7/nsubjs*1.14 0.2])
      imagesc(m3,sdratiolim); 
      h=colorbar; pp=get(h,'Position'); set(h,'Position',[pp(1:2) pp(4)/12 pp(4)]); 
      axis off;
      hold on; contour(mask,[mask_thresh mask_thresh],'k');hold off;
      axes('position',[0.90 1-3*0.3 0.7/nsubjs*1.14 0.2])
      imagesc((yr-d.origin(2))*d.vox(2),(xr-d.origin(1))*d.vox(1),m4,[0 15]); 
      h=colorbar; pp=get(h,'Position'); set(h,'Position',[pp(1:2) pp(4)/12 pp(4)]); 
      xlabel('y (mm)'); ylabel(['      ';'x (mm)']);
      axes('position',[0.90 1-3*0.3 0.7/nsubjs*1.14 0.2])
      imagesc(m4,[0 15]); 
      h=colorbar; pp=get(h,'Position'); set(h,'Position',[pp(1:2) pp(4)/12 pp(4)]); 
      axis off;
      hold on; contour(mask,[mask_thresh mask_thresh],'k');hold off;
      saveas(gcf,['c:/keith/papers/fiac/fig' type contr(icontr,:) md(imd,:)],'epsc2')
   end
end
end

%%%%%%%%%%%%%%%%%%%%%

fwhm_varatio=[]; 
for itype=1:3
type=deblank(types(itype,:))
for imd=1
   for icontr=2:4
      output_file_base=['c:/keith/fMRI/contest/multi/multi' type contr(icontr,:) md(imd,:)];
      d=fmris_read_image([output_file_base '_rfx.img'],0,0);
      fwhm_varatio=[fwhm_varatio d.fwhm(2)];
   end
end
end
fwhm_varatio
min(fwhm_varatio)
max(fwhm_varatio)


%%%%%%%%%%%%%%%%%%%%%

clf; view_slices('c:/keith/fMRI/contest/fiac1/fiac1_fonc1_all_cor.img')
clf; view_slices('c:/keith/fMRI/contest/fiac1/fiac1_fonc2_all_cor.img')
clf; view_slices('c:/keith/fMRI/contest/fiac1/fiac1_fonc3_all_cor.img')
clf; view_slices('c:/keith/fMRI/contest/fiac1/fiac1_fonc4_all_cor.img')

slicetimes=1.25;
frametimes=(0:190)*2.5;
contrast=[0.25 0.25 0.25 0.25;
          -0.5 -0.5 0.5 0.5;
          -0.5 0.5 -0.5 0.5;
          1 -1 -1 1];
exclude=[];
rho=0.5;
subj=0;
types=['_evt '; '_bloc'];
runs=[3 1];
sd_efs=[];
for itype=1:2
   type=deblank(types(itype,:))
   run=runs(itype)
   for imd=1:2
      evt=load(['c:/keith/fMRI/contest/fiac' num2str(subj) ...
            '/subj' num2str(subj) type '_fonc' num2str(run) '.txt']);
      nevt=size(evt,1);
      events=[evt(:,2) evt(:,1) zeros(nevt,1), ones(nevt,1)];
         if itype==1
            events(1,1)=5;
         else
            events((0:15)*6+1,1)=5;
         end
      X_cache=fmridesign(frametimes,slicetimes,events);
      contrast_is_delay=zeros(1,4)+imd-1;
      num_hrf_bases=zeros(1,4)+2;
      mag_T=5;
      del_ef=0;
      confounds=[];
      n_temporal=3;
      [sd_ef, Y]=efficiency(X_cache,contrast,exclude,rho,n_temporal, ...
         confounds, contrast_is_delay, mag_T, del_ef, num_hrf_bases);
      sd_efs=[sd_efs sd_ef];
   end
end

type =

_evt


run =

     3


sd_ef =

    2.5135
    0.9373
    0.8297
    1.8389


sd_ef =

    0.6050
    0.1161
    0.1161
    0.2471


type =

_bloc


run =

     1


sd_ef =

    0.5215
    0.9234
    0.8785
    1.7802


sd_ef =

    0.3469
    0.7164
    0.7220
    1.4511
    
sd_efs


%%%%%%%%%%%%%%%%%%%

clf; view_slices('c:/brainstat/testdata/avganat.img');
figure(2); clf; view_slices('c:/brainstat/testdata/avganat2.img');

%%%%%%%%%%%%%%%%%

c=[];
for isubj=1:nsubjs
   subj=subjs(isubj)
   for irun=1:4
      run=runs(subj+1,irun)
      if run>0
         base=['c:/keith/fMRI/contest/fiac' num2str(subj) ...
               '/fiac' num2str(subj) '_fonc' num2str(run)];
         cofile=[base '_all_cor.img'];
         d=fmris_read_image(cofile,0,0);
         c=[c d.fwhm(1)];
      end
   end
end
c
mean(c(c>0))
min(c(c>0))
max(c(c>0))


%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%

types=['_evt '; '_bloc'; '_comb'];
for itype=1:3
   
type=deblank(types(itype,:))
nmd=2;
if itype==3
   nmd=1;
end

for icontr=1:4
   for imd=1:nmd
      input_files_ef=[];
      input_files_sd=[];
      for isubj=1:nsubjs
         subj=subjs(isubj);
         if subj>=10
            blank=[];
         else
            blank=' ';
         end
         output_file_base=['c:/keith/fMRI/contest/subj/subj' num2str(subj) ...
               type contr(icontr,:) md(imd,:) ];
         input_files_ef=[input_files_ef; [output_file_base '_ef.img' blank]];
         input_files_sd=[input_files_sd; [output_file_base '_sd.img' blank]];
      end
      output_file_base=['c:/keith/fMRI/contest/multi_nosmooth/multi' type contr(icontr,:) md(imd,:)];
      which_stats='_ef _sd _t _fwhm _rfx';
      multistat(input_files_ef,input_files_sd,[],[],ones(nsubjs,1),1,output_file_base,which_stats,0);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%

min_fmri=['c:/keith/fMRI/contest/subj/mask' type '.img']
min_thresh=fmri_mask_thresh(min_fmri)
mask_del_file=['c:/keith/fMRI/contest/multi/mask' type '_del_file.img'];
mask_file=['c:/keith/fMRI/contest/multi/multi' type '_all_mag_t.img'];
math_vol(mask_file,min_fmri,['b=min(a{1}/5,a{2}/' num2str(min_thresh) ');'],mask_del_file);

for imd=1:nmd
   for icontr=1:4
      if imd==1
         mask_file=min_fmri;
         mask_thresh=min_thresh;
         input_thresh=0.001;
      else
         mask_file=mask_del_file;
         mask_thresh=1;
         input_thresh=0.01;
      end
      output_file_base=['c:/keith/fMRI/contest/multi_nosmooth/multi' type contr(icontr,:) md(imd,:)]
      stats_file_base=['c:/keith/fMRI/contest/stats_nosmooth/multi' type contr(icontr,:) md(imd,:)]
      for iflip=1:2
         diary([stats_file_base '_flip' num2str(iflip) '.txt'])
         stat_summary([output_file_base '_t.img'], ...
            [output_file_base '_fwhm.img'],[],mask_file,mask_thresh,input_thresh,3-iflip*2);
         diary('off')
         saveas(gcf,[stats_file_base '_flip' num2str(iflip) '.eps'],'epsc2');
      end
   end
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


d=fmris_read_image('c:/keith/fMRI/contest/multi/multi_evt_all_del_t.img',36,1)

fid=fopen('c:/keith/papers/fiac/multi_comb_all_mag_t_slice36.txt','w')
fprintf(fid,'%f ',d.data);
fclose(fid)

clf;
view_slices('c:/keith/fMRI/contest/multi/multi_evt_all_del_t.img',min_fmri,min_thresh,9:73,1,[-5 5])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

types=['_evt '; '_bloc'; '_comb'];
for itype=1:3
   type=deblank(types(itype,:))
   nmd=1;
   if itype==1
      nmd=2;
   end
   
   min_fmri=['c:/keith/fMRI/contest/subj/mask' type '.img']
   min_thresh=fmri_mask_thresh(min_fmri)
   mask_del_file=['c:/keith/fMRI/contest/multi/mask' type '_del_file.img'];
   
   for imd=1:nmd
      for icontr=2:4
         if imd==1
            mask_file=min_fmri;
            mask_thresh=min_thresh;
            input_thresh=0.001;
         else
            mask_file=mask_del_file;
            mask_thresh=1;
            input_thresh=0.01;
         end
         output_file_base=['c:/keith/fMRI/contest/multi_nosmooth/multi' type contr(icontr,:) md(imd,:)]
         stats_file_base=['c:/keith/fMRI/contest/stats_nosmooth_nodlm/multi' type contr(icontr,:) md(imd,:)]
         for iflip=1:2
            diary([stats_file_base '_flip' num2str(iflip) '.txt'])
            stat_summary_nodlm([output_file_base '_t.img'], ...
               [output_file_base '_fwhm.img'],[],mask_file,mask_thresh,input_thresh,3-iflip*2);
            diary('off')
            saveas(gcf,[stats_file_base '_flip' num2str(iflip) '.eps'],'epsc2');
         end
      end
   end
   
end


types=['_evt '; '_bloc'; '_comb'];
for itype=1:3
   type=deblank(types(itype,:))
   nmd=1;
   if itype==1
      nmd=2;
   end
   
   min_fmri=['c:/keith/fMRI/contest/subj/mask' type '.img']
   min_thresh=fmri_mask_thresh(min_fmri)
   mask_del_file=['c:/keith/fMRI/contest/multi/mask' type '_del_file.img'];
   
   for imd=1:nmd
      for icontr=2:4
         if imd==1
            mask_file=min_fmri;
            mask_thresh=min_thresh;
            input_thresh=0.001;
         else
            mask_file=mask_del_file;
            mask_thresh=1;
            input_thresh=0.01;
         end
         output_file_base=['c:/keith/fMRI/contest/multi/multi' type contr(icontr,:) md(imd,:)]
         stats_file_base=['c:/keith/fMRI/contest/stats_nodlm/multi' type contr(icontr,:) md(imd,:)]
         for iflip=1:2
            diary([stats_file_base '_flip' num2str(iflip) '.txt'])
            stat_summary_nodlm([output_file_base '_t.img'], ...
               [output_file_base '_fwhm.img'],[],mask_file,mask_thresh,input_thresh,3-iflip*2);
            diary('off')
            saveas(gcf,[stats_file_base '_flip' num2str(iflip) '.eps'],'epsc2');
         end
      end
   end
   
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% save c:/keith/papers/fiac/X.mat X

load c:/keith/papers/fiac/X.mat

Y=X;
j=[7 15 13 11 9 14 12 10 8 6 5 4 3 2 1];
j=[15 14 12 10 8 13 11 9 7 6 5 4 3 2 1];
for i=1:size(X,2)
   if (max(X(:,i))-min(X(:,i)))==0
      Y(:,i)=j(i);
   else
      Y(:,i)=(X(:,i)-min(X(:,i)))/(max(X(:,i))-min(X(:,i)))*0.8+0.1+j(i)-0.5;
   end
end

clf;
axes('Position',[0.2 0.2 0.6 0.45])
plot(1:191,Y,'k'); ylim([0.5 15.5]); xlim([0 191])
axis off;
l=['1st snt in block'
   'S snt, S spk, B1'
   'S snt, S spk, B2' 
   'S snt, D spk, B1'
   'S snt, D spk, B2' 
   'D snt, S spk, B1'
   'D snt, S spk, B2' 
   'D snt, D spk, B1'
   'D snt, D spk, B2' 
   '        Constant'
   '          Linear'
   '       Quadratic'
   '           Cubic'
   '          Spline'
   ' Whole brain avg']
for i=1:15
   text(-40,16-i,l(i,:));
end
saveas(gcf,'c:/keith/papers/fiac/figX.eps','epsc2');
