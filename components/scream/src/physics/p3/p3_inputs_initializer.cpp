#include "physics/p3/p3_inputs_initializer.hpp"
#include "physics/p3/p3_main_impl.hpp"
#include "ekat/util/ekat_file_utils.hpp"

#include <array>
#include <fstream>

namespace scream
{

void P3InputsInitializer::add_field (const field_type &f)
{
  const auto& id = f.get_header().get_identifier();
  
  m_fields.emplace(id.name(),f);
  m_fields_id.insert(id);
}

void P3InputsInitializer::
add_field (const field_type &f, const field_type& f_ref,
           const remapper_ptr_type& remapper)
{
  if (m_remapper) {
    // Sanity check
    EKAT_REQUIRE_MSG (m_remapper->get_src_grid()->name()==remapper->get_src_grid()->name(),
      "Error! A remapper was already set in P3InputsInitializer, but its src grid differs from"
      "       the grid of the input remapper of this call.\n");
  } else {
    m_remapper = remapper;
    m_remapper->registration_begins();
  }

  const auto& id = f.get_header().get_identifier();
  const auto& id_ref = f_ref.get_header().get_identifier();

  // To the AD, we only expose the fact that we init f_ref...
  m_fields_id.insert(id_ref);

  // ...but P3 only knows how to init f...
  m_fields.emplace(id.name(),f);

  // ...hence, we remap to f_ref.
  m_remapper->register_field(f, f_ref);
}


// =========================================================================================
void P3InputsInitializer::initialize_fields ()
{
  using namespace p3;
  using P3F             = Functions<Real, DefaultDevice>;
  using Spack           = typename P3F::Spack;
  using Pack            = ekat::Pack<Real,Spack::n>;
  using view_2d  = typename P3F::view_2d<Spack>;

  // Safety check: if we're asked to init anything at all,
  // To simplify the initializer we first define all the fields we expect to have to initialize.
  std::vector<std::string> fields_to_init;
  fields_to_init.push_back("T_atm");
  fields_to_init.push_back("ast");
  fields_to_init.push_back("ni_activated");
  fields_to_init.push_back("nc_nuceat_tend");
  fields_to_init.push_back("pmid");
  fields_to_init.push_back("dp");
  fields_to_init.push_back("zi");
  fields_to_init.push_back("qv_prev");
  fields_to_init.push_back("T_prev");
  fields_to_init.push_back("qv");
  fields_to_init.push_back("qc");
  fields_to_init.push_back("qr");
  fields_to_init.push_back("qi");
  fields_to_init.push_back("qm");
  fields_to_init.push_back("nc");
  fields_to_init.push_back("nr");
  fields_to_init.push_back("ni");
  fields_to_init.push_back("bm");
  fields_to_init.push_back("nccn_prescribed");
  fields_to_init.push_back("inv_qc_relvar");
  int count = 0;
  std::string list_of_fields = "";
  for (auto name : fields_to_init)
  {
    list_of_fields += name;
    list_of_fields += ", ";
    count += m_fields.count(name);
  }
 
  EKAT_REQUIRE_MSG(count!=0,"Error in p3_inputs_initializer: no fields have declared this initializer.  Check p3 interface."); 

  EKAT_REQUIRE_MSG (count==(int)fields_to_init.size(),
    "Error! P3InputsInitializer is expected to init " + std::to_string(fields_to_init.size()) + " fields:\n"
    "       " + list_of_fields + "\n"
    "       Instead found " + std::to_string(count) + " fields.\n"
    "       Please, check the atmosphere processes you are using,\n"
    "       and make sure they agree on who's initializing each field.\n");

  // Initialize the fields that we expect.
  // Get device views
  auto d_T_atm           = m_fields.at("T_atm").get_reshaped_view<Pack**>();
  auto d_ast             = m_fields.at("ast").get_reshaped_view<Pack**>();
  auto d_ni_activated    = m_fields.at("ni_activated").get_reshaped_view<Pack**>();
  auto d_nc_nuceat_tend  = m_fields.at("nc_nuceat_tend").get_reshaped_view<Pack**>();
  auto d_pmid            = m_fields.at("pmid").get_reshaped_view<Pack**>();
  auto d_dp              = m_fields.at("dp").get_reshaped_view<Pack**>();
  auto d_zi              = m_fields.at("zi").get_reshaped_view<Pack**>();
  auto d_qv_prev         = m_fields.at("qv_prev").get_reshaped_view<Pack**>();
  auto d_T_prev          = m_fields.at("T_prev").get_reshaped_view<Pack**>();
  auto d_qv              = m_fields.at("qv").get_reshaped_view<Pack**>();
  auto d_qc              = m_fields.at("qc").get_reshaped_view<Pack**>();
  auto d_qr              = m_fields.at("qr").get_reshaped_view<Pack**>();
  auto d_qi              = m_fields.at("qi").get_reshaped_view<Pack**>();
  auto d_qm              = m_fields.at("qm").get_reshaped_view<Pack**>();
  auto d_nc              = m_fields.at("nc").get_reshaped_view<Pack**>();
  auto d_nr              = m_fields.at("nr").get_reshaped_view<Pack**>();
  auto d_ni              = m_fields.at("ni").get_reshaped_view<Pack**>();
  auto d_bm              = m_fields.at("bm").get_reshaped_view<Pack**>();
  auto d_nccn_prescribed = m_fields.at("nccn_prescribed").get_reshaped_view<Pack**>();
  auto d_inv_qc_relvar   = m_fields.at("inv_qc_relvar").get_reshaped_view<Pack**>();

  // Set local views which are used in some of the initialization
  auto mdims = m_fields.at("qc").get_header().get_identifier().get_layout();
  Int ncol = mdims.dim(0); 
  Int nk   = mdims.dim(1);
  const Int nk_pack = ekat::npack<Spack>(nk);
  view_2d d_th_atm("th_atm",ncol,nk_pack);        
  view_2d d_dz("dz",ncol,nk_pack);                
  view_2d d_exner("exner",ncol,nk_pack);          
  
  // Create host mirrors for all views
  auto h_T_atm            = Kokkos::create_mirror_view(d_T_atm          ); 
  auto h_ast              = Kokkos::create_mirror_view(d_ast            ); 
  auto h_ni_activated     = Kokkos::create_mirror_view(d_ni_activated   ); 
  auto h_nc_nuceat_tend   = Kokkos::create_mirror_view(d_nc_nuceat_tend ); 
  auto h_pmid             = Kokkos::create_mirror_view(d_pmid           ); 
  auto h_dp               = Kokkos::create_mirror_view(d_dp             ); 
  auto h_zi               = Kokkos::create_mirror_view(d_zi             ); 
  auto h_qv_prev          = Kokkos::create_mirror_view(d_qv_prev        ); 
  auto h_T_prev           = Kokkos::create_mirror_view(d_T_prev         ); 
  auto h_qv               = Kokkos::create_mirror_view(d_qv             ); 
  auto h_qc               = Kokkos::create_mirror_view(d_qc             ); 
  auto h_qr               = Kokkos::create_mirror_view(d_qr             ); 
  auto h_qi               = Kokkos::create_mirror_view(d_qi             ); 
  auto h_qm               = Kokkos::create_mirror_view(d_qm             ); 
  auto h_nc               = Kokkos::create_mirror_view(d_nc             ); 
  auto h_nr               = Kokkos::create_mirror_view(d_nr             ); 
  auto h_ni               = Kokkos::create_mirror_view(d_ni             ); 
  auto h_bm               = Kokkos::create_mirror_view(d_bm             ); 
  auto h_nccn_prescribed  = Kokkos::create_mirror_view(d_nccn_prescribed); 
  auto h_inv_qc_relvar    = Kokkos::create_mirror_view(d_inv_qc_relvar  ); 
  auto h_th_atm           = Kokkos::create_mirror_view(d_th_atm         ); 
  auto h_dz               = Kokkos::create_mirror_view(d_dz             ); 
  auto h_exner            = Kokkos::create_mirror_view(d_exner          ); 

 // Initalize from text file 
  std::ifstream fid("p3_init_vals.txt", std::ifstream::in);
  EKAT_REQUIRE_MSG(!fid.fail(),"Error in p3_inputs_initializer.cpp loading p3_init_vals.txt file");
  std::string tmp_line;
  getline(fid,tmp_line);  // Read header and discard.
  int icol_in_max = 0;
  while(getline(fid,tmp_line))
  {
    std::stringstream s(tmp_line);
    std::string field;
    std::vector<Real> field_vals;
    std::string skip;
    int icol, k, ipack, ivec;
    s >> icol >> k;
    ipack = k / Spack::n;
    ivec  = k % Spack::n;
    icol_in_max = std::max(icol,icol_in_max);
    s >> h_qv(icol,ipack)[ivec]             ;
    s >> h_th_atm(icol,ipack)[ivec]         ;
    s >> h_pmid(icol,ipack)[ivec]           ;
    s >> h_dz(icol,ipack)[ivec]             ;
    s >> h_nc_nuceat_tend(icol,ipack)[ivec] ;
    s >> h_nccn_prescribed(icol,ipack)[ivec];
    s >> h_ni_activated(icol,ipack)[ivec]   ;
    s >> h_inv_qc_relvar(icol,ipack)[ivec]  ;
    s >> h_qc(icol,ipack)[ivec]             ;
    s >> h_nc(icol,ipack)[ivec]             ;
    s >> h_qr(icol,ipack)[ivec]             ;
    s >> h_nr(icol,ipack)[ivec]             ;
    s >> h_qi(icol,ipack)[ivec]             ;
    s >> h_ni(icol,ipack)[ivec]             ;
    s >> h_qm(icol,ipack)[ivec]             ;
    s >> h_bm(icol,ipack)[ivec]             ;
    for (int skp=0;skp<5;skp++) { s >> skip; }
    s >> h_dp(icol,ipack)[ivec]   ;
    s >> h_exner(icol,ipack)[ivec];
    for (int skp=0;skp<7;skp++) { s >> skip; }
    s >> h_ast(icol,ipack)[ivec];
    for (int skp=0;skp<6;skp++) { s >> skip; }
    s >> h_qv_prev(icol,ipack)[ivec];
    s >> h_T_prev(icol,ipack)[ivec] ;

  } // while getline(fid,tmp_line)
  // For now use dummy values copied from `p3_ic_cases.cpp`, which is loaded from a file.
  // That file only has data for 3 columns, need to expand to >3 columns.
  for (int icol_i = 0;icol_i<ncol;icol_i++)
  {
    for (int k = nk-1;k>=0;k--)
    {
    int icol  = icol_i % icol_in_max;
    int ipack = k / Spack::n;
    int ivec  = k % Spack::n;
    int ipack_m1 = (k-1) / Spack::n;
    int ivec_m1  = (k-1) % Spack::n;
    h_qv(icol_i,ipack)[ivec]              = h_qv(icol,ipack)[ivec]                              ;
    h_th_atm(icol_i,ipack)[ivec]          = h_th_atm(icol,ipack)[ivec]                          ;
    h_T_atm(icol_i,ipack)[ivec]           = h_th_atm(icol,ipack)[ivec]*h_exner(icol,ipack)[ivec];
    h_pmid(icol_i,ipack)[ivec]            = h_pmid(icol,ipack)[ivec]                            ;
    h_dz(icol_i,ipack)[ivec]              = h_dz(icol,ipack)[ivec]                              ;
    h_nc_nuceat_tend(icol_i,ipack)[ivec]  = h_nc_nuceat_tend(icol,ipack)[ivec]                  ;
    h_nccn_prescribed(icol_i,ipack)[ivec] = h_nccn_prescribed(icol,ipack)[ivec]                 ;
    h_ni_activated(icol_i,ipack)[ivec]    = h_ni_activated(icol,ipack)[ivec]                    ;
    h_inv_qc_relvar(icol_i,ipack)[ivec]   = h_inv_qc_relvar(icol,ipack)[ivec]                   ;
    h_qc(icol_i,ipack)[ivec]              = h_qc(icol,ipack)[ivec]                              ;
    h_nc(icol_i,ipack)[ivec]              = h_nc(icol,ipack)[ivec]                              ;
    h_qr(icol_i,ipack)[ivec]              = h_qr(icol,ipack)[ivec]                              ;
    h_nr(icol_i,ipack)[ivec]              = h_nr(icol,ipack)[ivec]                              ;
    h_qi(icol_i,ipack)[ivec]              = h_qi(icol,ipack)[ivec]                              ;
    h_ni(icol_i,ipack)[ivec]              = h_ni(icol,ipack)[ivec]                              ;
    h_qm(icol_i,ipack)[ivec]              = h_qm(icol,ipack)[ivec]                              ;
    h_bm(icol_i,ipack)[ivec]              = h_bm(icol,ipack)[ivec]                              ;
    h_dp(icol_i,ipack)[ivec]              = h_dp(icol,ipack)[ivec]                              ;
    h_exner(icol_i,ipack)[ivec]           = h_exner(icol,ipack)[ivec]                           ;
    h_ast(icol_i,ipack)[ivec]             = h_ast(icol,ipack)[ivec]                             ;
    h_qv_prev(icol_i,ipack)[ivec]         = h_qv_prev(icol,ipack)[ivec]                         ;
    h_T_prev(icol_i,ipack)[ivec]          = h_T_prev(icol,ipack)[ivec]                          ;
    // Initialize arrays not provided in input file
    h_zi(icol_i,ipack)[ivec] = (k==nk-1) ? 0 :
                                           h_zi(icol_i,ipack_m1)[ivec_m1] + h_dz(icol_i,ipack)[ivec];
    }
  }

  // Deep copy back to device
  Kokkos::deep_copy(d_T_atm          , h_T_atm          ); 
  Kokkos::deep_copy(d_ast            , h_ast            );
  Kokkos::deep_copy(d_ni_activated   , h_ni_activated   ); 
  Kokkos::deep_copy(d_nc_nuceat_tend , h_nc_nuceat_tend ); 
  Kokkos::deep_copy(d_pmid           , h_pmid           ); 
  Kokkos::deep_copy(d_dp             , h_dp             ); 
  Kokkos::deep_copy(d_zi             , h_zi             ); 
  Kokkos::deep_copy(d_qv_prev        , h_qv_prev        ); 
  Kokkos::deep_copy(d_T_prev         , h_T_prev         ); 
  Kokkos::deep_copy(d_qv             , h_qv             ); 
  Kokkos::deep_copy(d_qc             , h_qc             ); 
  Kokkos::deep_copy(d_qr             , h_qr             ); 
  Kokkos::deep_copy(d_qi             , h_qi             ); 
  Kokkos::deep_copy(d_qm             , h_qm             ); 
  Kokkos::deep_copy(d_nc             , h_nc             ); 
  Kokkos::deep_copy(d_nr             , h_nr             ); 
  Kokkos::deep_copy(d_ni             , h_ni             ); 
  Kokkos::deep_copy(d_bm             , h_bm             ); 
  Kokkos::deep_copy(d_nccn_prescribed, h_nccn_prescribed); 
  Kokkos::deep_copy(d_inv_qc_relvar  , h_inv_qc_relvar  ); 

  if (m_remapper) {
    m_remapper->registration_ends();

    m_remapper->remap(true);

    // Now we can destroy the remapper
    m_remapper = nullptr;
  }
}

} // namespace scream
