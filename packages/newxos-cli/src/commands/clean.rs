use crate::error::Result;
use crate::support::process::run_status;

pub fn run(args: Vec<String>) -> Result<i32> {
    if args.is_empty() {
        run_status("nh", &["clean", "all", "--keep", "1", "--keep-since", "0h"])
    } else {
        let mut nh_args = vec!["clean", "all"];
        nh_args.extend(args.iter().map(|s| s.as_str()));
        run_status("nh", &nh_args)
    }
}
